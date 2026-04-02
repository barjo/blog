module Search exposing (Embedding, embed, rank)

{-| Sparse-vector search using the hashing trick ([feature hashing](https://en.wikipedia.org/wiki/Feature_hashing)).

Each post is represented as a sparse vector of 512 buckets.
To embed a text we:

1.  **Tokenise** — lowercase, split on non-alphanumeric boundaries, drop
    single-char tokens and stopwords. Stopwords ("the", "is", "and" …) appear
    in every post so they add weight everywhere equally. It's noise that dilutes
    the signal from meaningful words.

2.  **Hash into buckets** — each token is hashed to a bucket index in
    [0, 512). The hash is deterministic so the same word always lands in the
    same bucket. Collisions happen (two different words can share a bucket)
    but with 512 buckets the overlap is tolerable for a small blog.

3.  **Weight with log-TF** — raw term frequency would give a word appearing
    100× a weight of 100, which is way too much. `1 + log(count)` compresses
    that: 1 occurrence → 1.0, 10 → 3.3, 100 → 5.6. Diminishing returns so
    no single word dominates. Bigrams (adjacent word pairs) are also added
    with half weight to capture phrases.

4.  **L2-normalise** — divide every bucket by the vector's length
    (`sqrt(sum of squares)`) so the total magnitude becomes 1. Without this,
    a 2 000-word post would have much larger values than a 50-word post and
    cosine similarity would favour long posts regardless of relevance.
    Normalising puts all posts on equal footing. Only the _direction_ of the
    vector matters, not its size.

5.  **Sparsify** — drop near-zero buckets to save space in the JSON index.

At query time, the same pipeline embeds the search string and we rank posts
by **cosine similarity** (dot product of two unit vectors = how much they
point in the same direction). A bonus is added for direct title and tag
matches so exact hits always surface even if hash collisions dilute the
embedding score.

-}

import Dict exposing (Dict)
import Post exposing (Post)
import Set exposing (Set)


{-| Sparse embedding: list of (bucket index, weight) pairs.
-}
type alias Embedding =
    List ( Int, Float )



-- Constants


{-| Number of buckets in the hash vector. Larger = fewer collisions but
bigger index.json. 512 is a reasonable trade-off for a small blog.
-}
vectorSize : Int
vectorSize =
    512



-- Hashing


{-| Hash a string to a bucket in [0, vectorSize).
Accumulates h = (h × 31 + charCode) mod 0x7FFFFFFF per character, then
takes mod vectorSize. The large intermediate modulus (a Mersenne prime)
gives good distribution before the final bucketing.
-}
hash : String -> Int
hash str =
    str
        |> String.foldl (\c h -> modBy 0x7FFFFFFF (h * 31 + Char.toCode c)) 0
        |> modBy vectorSize



-- Tokenisation


{-| Lowercase, replace non-alphanumeric with space, split, drop stopwords and
single-char tokens.
-}
tokenize : String -> List String
tokenize text =
    text
        |> String.toLower
        |> String.toList
        |> List.map
            (\c ->
                if Char.isAlphaNum c then
                    c

                else
                    ' '
            )
        |> String.fromList
        |> String.words
        |> List.filter (\t -> String.length t > 1 && not (Set.member t stopwords))



-- Embedding


{-| Build a sparse, L2-normalised embedding from raw text.
-}
embed : String -> Embedding
embed text =
    let
        tokens =
            tokenize text

        -- Count how many times each token appears.
        tf =
            List.foldl
                (\t d -> Dict.update t (\v -> Just (Maybe.withDefault 0 v + 1)) d)
                Dict.empty
                tokens

        -- Hash each unique token into a bucket, weighted by log-TF.
        unigrams =
            Dict.foldl
                (\token count d ->
                    let
                        idx =
                            hash token

                        weight =
                            1 + logBase e (toFloat count)
                    in
                    Dict.update idx (\v -> Just (Maybe.withDefault 0 v + weight)) d
                )
                Dict.empty
                tf

        -- Adjacent word pairs, half weight, to capture phrases.
        withBigrams =
            addBigrams tokens unigrams

        -- L2 norm: sqrt(sum of squares).
        norm =
            Dict.values withBigrams
                |> List.foldl (\v acc -> acc + v * v) 0
                |> sqrt
    in
    if norm > 0 then
        withBigrams
            |> Dict.map (\_ v -> v / norm)
            |> Dict.toList
            |> List.filter (\( _, v ) -> v > 0.001)

    else
        []


addBigrams : List String -> Dict Int Float -> Dict Int Float
addBigrams tokens vector =
    case tokens of
        a :: ((b :: _) as rest) ->
            let
                idx =
                    hash (a ++ "_" ++ b)
            in
            addBigrams rest
                (Dict.update idx (\v -> Just (Maybe.withDefault 0 v + 0.5)) vector)

        _ ->
            vector



-- Ranking


{-| Rank posts by a hybrid score: cosine similarity on embeddings + direct
title and tag matching so exact hits always surface.
-}
rank : String -> List Post -> List ( Post, Float )
rank query posts =
    let
        trimmed =
            String.trim query
    in
    if String.isEmpty trimmed then
        []

    else
        let
            qEmb =
                embed trimmed |> Dict.fromList

            lowerQuery =
                String.toLower trimmed

            queryTokens =
                tokenize trimmed
        in
        posts
            |> List.map (\p -> ( p, score qEmb lowerQuery queryTokens p ))
            |> List.filter (\( _, s ) -> s > 0.01)
            |> List.sortBy (\( _, s ) -> negate s)


score : Dict Int Float -> String -> List String -> Post -> Float
score qEmb lowerQuery queryTokens post =
    let
        embScore =
            cosineSimilarity qEmb post.embedding

        titleBonus =
            if String.contains lowerQuery (String.toLower post.title) then
                0.3

            else
                0

        tagBonus =
            queryTokens
                |> List.filter (\t -> List.member t (List.map String.toLower post.tags))
                |> List.length
                |> toFloat
                |> (*) 0.25
    in
    embScore + titleBonus + tagBonus


{-| Dot product of two unit vectors = cosine of the angle between them.
Ranges from 0 (unrelated) to 1 (identical direction).
-}
cosineSimilarity : Dict Int Float -> Embedding -> Float
cosineSimilarity queryDict postEmb =
    List.foldl
        (\( idx, weight ) acc ->
            case Dict.get idx queryDict of
                Just qw ->
                    acc + qw * weight

                Nothing ->
                    acc
        )
        0
        postEmb



-- Stopwords


{-| Common words that appear in every post and add no distinguishing signal.
-}
stopwords : Set String
stopwords =
    Set.fromList
        [ "a"
        , "an"
        , "the"
        , "and"
        , "or"
        , "but"
        , "in"
        , "on"
        , "at"
        , "to"
        , "for"
        , "of"
        , "with"
        , "by"
        , "from"
        , "is"
        , "it"
        , "as"
        , "be"
        , "was"
        , "are"
        , "this"
        , "that"
        , "not"
        , "we"
        , "you"
        , "can"
        , "will"
        , "just"
        , "if"
        , "so"
        , "no"
        , "do"
        , "my"
        , "has"
        , "had"
        , "have"
        , "been"
        , "would"
        , "could"
        , "should"
        , "their"
        , "there"
        , "they"
        , "what"
        , "which"
        , "when"
        , "how"
        , "all"
        , "each"
        , "every"
        , "both"
        , "few"
        , "more"
        , "most"
        , "other"
        , "some"
        , "such"
        , "than"
        , "too"
        , "very"
        , "also"
        , "about"
        , "up"
        , "out"
        , "into"
        , "over"
        , "after"
        , "then"
        , "them"
        , "these"
        , "those"
        , "its"
        , "only"
        , "own"
        , "same"
        , "here"
        , "where"
        , "while"
        , "who"
        , "whom"
        , "between"
        , "through"
        , "during"
        , "before"
        , "being"
        , "did"
        , "does"
        , "one"
        , "two"
        , "three"
        , "he"
        , "she"
        , "him"
        , "her"
        , "his"
        , "our"
        , "your"
        , "any"
        , "may"
        , "use"
        , "used"
        , "using"
        , "get"
        , "make"
        , "like"
        , "new"
        , "way"
        , "well"
        , "now"
        , "even"
        , "must"
        , "need"
        ]

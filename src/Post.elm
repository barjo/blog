module Post exposing (Post, fetchIndex, fetchPost, findBySlug)

{-| Post data, decoding and fetching.
-}

import Http
import Json.Decode as Decode


{-| Layout of a blog post metadata.
-}
type alias Post =
    { slug : String
    , title : String
    , date : String
    , description : String
    , tags : List String
    , embedding : List ( Int, Float )
    }



-- Decoding


{-| Decode a single post from JSON.
-}
decoder : Decode.Decoder Post
decoder =
    Decode.map6 Post
        (Decode.field "slug" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "date" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "tags" (Decode.list Decode.string))
        (Decode.oneOf
            [ Decode.field "embedding" (Decode.list Decode.float |> Decode.map pairsFromFlat)
            , Decode.succeed []
            ]
        )


{-| Decode flat [idx, val, idx, val, …] into pairs.
-}
pairsFromFlat : List Float -> List ( Int, Float )
pairsFromFlat flat =
    case flat of
        i :: v :: rest ->
            ( round i, v ) :: pairsFromFlat rest

        _ ->
            []



-- Fetching


{-| Fetch the post index from posts/index.json.
-}
fetchIndex : (Result Http.Error (List Post) -> msg) -> Cmd msg
fetchIndex toMsg =
    Http.get
        { url = "posts/index.json"
        , expect = Http.expectJson toMsg (Decode.list decoder)
        }


{-| Fetch a post markdown content by slug.
-}
fetchPost : String -> (Result Http.Error String -> msg) -> Cmd msg
fetchPost slug toMsg =
    Http.get
        { url = "posts/" ++ slug ++ ".md"
        , expect = Http.expectString toMsg
        }



-- Helpers


{-| Find a post by its slug. Returns Nothing if not found.
-}
findBySlug : String -> List Post -> Maybe Post
findBySlug slug =
    List.filter (\p -> p.slug == slug) >> List.head

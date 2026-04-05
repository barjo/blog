You probably have heard about embeddings, especially in the context of neural networks and LLMs. But you don't need a neural network to compute them. The [hashing trick](https://en.wikipedia.org/wiki/Feature_hashing) (a.k.a. feature hashing) is a simpler technique. It's useful on its own and a great way to build intuition about what embeddings actually are. I had a bit of fun adding a search feature to this blog using it.

## What's an embedding anyway?

An embedding is just a list of numbers (vector) that represents something. A blog post, a sentence, a word, anything. For example, the word "daydream" might be represented as `[0, 0, 0.7, 0, 0, 0.3, 0, 0]`. Mostly zeros, with weight in a couple of positions. The word "dream" might land weight in some of the same positions, making their vectors similar. The word "froth" would light up completely different ones.

The key idea is that *similar things should be mapped to similar numbers*. In the context of this blog, if two posts are about the same topic, their embeddings should point in roughly the same direction.

## The hashing trick

Instead of training a neural network to learn those numbers, we can compute them. The hashing trick works like this:

1. Take some text, split it into words
2. Hash each word to get a bucket index (a position in the vector)
3. Add weight to that bucket, roughly how many times the word appears
4. Normalize the whole vector so its length is 1

The hash tells you *where* in the vector a word lives, and the value at that position tells you *how important* that word is in the text. Two texts that share words will light up the same buckets, and their vectors will be similar. That's our embedding.

Here's what the pipeline looks like:

![Hashing trick pipeline — text to tokens to hash to sparse vector, then comparing two vectors by shared buckets](images/hashing-trick-pipeline.svg)

## Drilling down

First, we need a hash function. It takes a word and returns a bucket index:

```js
function hash(word) -> int:
    h = 0
    for each char in word:
        h = (h * 31 + charCode(char)) mod LARGE_PRIME
    return h mod VECTOR_SIZE
```

Here we use a polynomial [rolling hash](https://en.wikipedia.org/wiki/Rolling_hash), that uses the word characters and a big prime number to help spread values evenly. It's deterministic, the same word always gives the same bucket.

Then the embedding function itself. We tokenize, count how often each word appears, and hash everything into a unit vector:

```js
function embed(text) -> vector:
    tokens = tokenize(text)
    counts = frequency(tokens)
    vector = new array[VECTOR_SIZE]

    for each (word, count) in counts:
        idx = hash(word)
        vector[idx] += 1 + log(count)

    return normalize(vector)
```

Let's unpack that.

**Tokenize** splits the text into lowercase words and drops stopwords (words like "the", "is", "and" that appear everywhere). They would light up the same buckets in every post, adding noise without helping distinguish one from another.

**`1 + log(count)`** is the weighting. Using the raw count would give a word appearing 100 times a weight of 100, which is too much. Log compresses that: 1→1.0, 10→3.3, 100→5.6. Diminishing returns so no single word dominates.

**Normalize** divides every bucket by the vector's total length (`sqrt(sum of squares)`) so the magnitude becomes 1. Without this, long posts would always have larger vectors than short ones, and similarity would favor length over relevance. Normalizing means only the *direction* matters.

### Comparing embeddings

Now that we can embed text into a vector, how do we compare two of them? With the dot product, a.k.a. [cosine similarity](https://en.wikipedia.org/wiki/Cosine_similarity) for unit vectors:

```js
function similarity(a, b) -> float:
    score = 0
    for i in 0..VECTOR_SIZE:
        score += a[i] * b[i]
    return score
```

It ranges from 0 (nothing in common) to 1 (identical). Posts with higher scores rank first. Since our vectors are sparse, we only need to iterate over the non-zero buckets — most of the work is skipped.

### What about collisions?

A collision is when two different words hash to the same bucket. This blog doesn't have much content, so even with a small number (512) of buckets (i.e. vector size) the collisions don't matter too much because normalization ensures no single collision dominates the vector. If you need better precision, increase the vector size.

## Not a neural network, but useful

This won't compete with sentence-transformers or OpenAI embeddings on quality. Neural embeddings capture *semantic similarity* (i.e synonyms, paraphrases, related concepts), while the hashing trick only captures *lexical overlap*: same words, similar vectors. "Car" and "automobile" would land in completely different buckets here, but a neural embedding would place them close together.

But the beauty of the hashing trick is that you don't need a vocabulary, you don't need training, you don't even need to know what words exist ahead of time. You just hash and go.

## References

- [Feature hashing](https://en.wikipedia.org/wiki/Feature_hashing) — Wikipedia article on the hashing trick
- [Hashing Representations for Machine Learning](https://alex.smola.org/papers/2009/Weinbergeretal09.pdf) — the original paper by Weinberger et al. (2009)
- [Cosine similarity](https://en.wikipedia.org/wiki/Cosine_similarity) — how we compare two vectors
- [What Are Embeddings?](https://vickiboykis.com/what_are_embeddings/) — Vicki Boykis' excellent deep dive into embeddings
- [Blog code](https://github.com/barjo/blog/blob/main/src/Search.elm) — this blog's search that leverages the hashing trick

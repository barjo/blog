port module Embed exposing (main)

{-| Worker that computes post embeddings at build time.
Receives post texts as flags, sends sparse embeddings back via port.

Usually port are use to offload to javascript, here we do kind of the opposite, (^O^)/, the script
call Elm so that we can reuse the same code to compute embeddings at build time.

-}

import Json.Decode as Decode
import Json.Encode as Encode
import Search


port embeddingsComputed : Encode.Value -> Cmd msg


type alias PostInput =
    { slug : String
    , text : String
    }


main : Program Decode.Value () ()
main =
    Platform.worker
        { init = init
        , update = \_ m -> ( m, Cmd.none )
        , subscriptions = \_ -> Sub.none
        }


init : Decode.Value -> ( (), Cmd msg )
init flags =
    ( ()
    , case Decode.decodeValue (Decode.list inputDecoder) flags of
        Ok inputs ->
            inputs
                |> List.map
                    (\{ slug, text } ->
                        Encode.object
                            [ ( "slug", Encode.string slug )
                            , ( "embedding", encodeEmbedding (Search.embed text) )
                            ]
                    )
                |> Encode.list identity
                |> embeddingsComputed

        Err err ->
            let
                _ =
                    Debug.log "Embed: failed to decode flags" err
            in
            embeddingsComputed (Encode.list identity [])
    )


inputDecoder : Decode.Decoder PostInput
inputDecoder =
    Decode.map2 PostInput
        (Decode.field "slug" Decode.string)
        (Decode.field "text" Decode.string)


{-| Flat encoding: [idx, val, idx, val, …] — no inner arrays.
-}
encodeEmbedding : Search.Embedding -> Encode.Value
encodeEmbedding pairs =
    pairs
        |> List.concatMap
            (\( i, v ) ->
                [ Encode.int i
                , Encode.float (toFloat (round (v * 1000)) / 1000)
                ]
            )
        |> Encode.list identity

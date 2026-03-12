module Render exposing (render)

{-| Custom markdown renderer with syntax highlighting.
-}

import Html exposing (..)
import Html.Attributes exposing (..)
import Markdown.Parser
import Markdown.Renderer
import SyntaxHighlight


{-| Render a markdown string to Html.
-}
render : String -> Html msg
render markdown =
    case
        markdown
            |> Markdown.Parser.parse
            |> Result.mapError (\_ -> "Parsing error")
            |> Result.andThen (Markdown.Renderer.render renderer)
    of
        Ok rendered ->
            div [] rendered

        Err error ->
            p [] [ text ("Error rendering markdown: " ++ error) ]



-- Internals


renderer : Markdown.Renderer.Renderer (Html msg)
renderer =
    let
        default =
            Markdown.Renderer.defaultHtmlRenderer
    in
    { default | codeBlock = codeBlock }


codeBlock : { body : String, language : Maybe String } -> Html msg
codeBlock { body, language } =
    let
        highlighter =
            case language of
                Just "elm" ->
                    SyntaxHighlight.elm

                Just "js" ->
                    SyntaxHighlight.javascript

                Just "javascript" ->
                    SyntaxHighlight.javascript

                Just "json" ->
                    SyntaxHighlight.json

                Just "xml" ->
                    SyntaxHighlight.xml

                Just "html" ->
                    SyntaxHighlight.xml

                Just "css" ->
                    SyntaxHighlight.css

                Just "python" ->
                    SyntaxHighlight.python

                Just "sql" ->
                    SyntaxHighlight.sql

                Just "nix" ->
                    SyntaxHighlight.nix

                _ ->
                    SyntaxHighlight.noLang
    in
    case highlighter (String.trim body) of
        Ok highlighted ->
            SyntaxHighlight.toBlockHtml Nothing highlighted

        Err _ ->
            pre [] [ code [] [ text body ] ]

module Theme exposing (Theme(..), codeStyle, fromString, icon, toString, toggle)

{-| Dark/Light theme type with conversion helpers.
-}

import Html exposing (Html)
import Icon
import SyntaxHighlight


type Theme
    = Dark
    | Light
    | Radical


fromString : String -> Theme
fromString s =
    case s of
        "dark" ->
            Dark

        "radical" ->
            Radical

        _ ->
            Light


toString : Theme -> String
toString theme =
    case theme of
        Dark ->
            "dark"

        Light ->
            "light"

        Radical ->
            "radical"


toggle : Theme -> Theme
toggle theme =
    case theme of
        Dark ->
            Light

        Light ->
            Dark

        Radical ->
            Light


icon : Theme -> Html msg
icon theme =
    case theme of
        Dark ->
            Icon.moon

        Light ->
            Icon.sun

        Radical ->
            Icon.smiley


codeStyle : Theme -> Html msg
codeStyle theme =
    case theme of
        Dark ->
            SyntaxHighlight.useTheme SyntaxHighlight.monokai

        Light ->
            SyntaxHighlight.useTheme SyntaxHighlight.gitHub

        Radical ->
            SyntaxHighlight.useTheme SyntaxHighlight.monokai

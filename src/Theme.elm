module Theme exposing (Theme(..), codeStyle, fromString, icon, toString, toggle)

{-| Dark/Light theme type with conversion helpers.
-}

import Html exposing (Html)
import Icon
import SyntaxHighlight


type Theme
    = Dark
    | Light


fromString : String -> Theme
fromString s =
    if s == "dark" then
        Dark

    else
        Light


toString : Theme -> String
toString theme =
    case theme of
        Dark ->
            "dark"

        Light ->
            "light"


toggle : Theme -> Theme
toggle theme =
    case theme of
        Dark ->
            Light

        Light ->
            Dark


icon : Theme -> Html msg
icon theme =
    case theme of
        Dark ->
            Icon.moon

        Light ->
            Icon.sun


codeStyle : Theme -> Html msg
codeStyle theme =
    case theme of
        Dark ->
            SyntaxHighlight.useTheme SyntaxHighlight.monokai

        Light ->
            SyntaxHighlight.useTheme SyntaxHighlight.gitHub

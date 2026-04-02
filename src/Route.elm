module Route exposing (Page(..), urlToPage)

{-| Hash-based routing for the blog.
-}

import Url


{-| Represents the current page.
-}
type Page
    = Home
    | TagView String
    | PostView String (Maybe String)
    | Search
    | NotFound


{-| Parse a URL fragment into a Page.
-}
urlToPage : Url.Url -> Page
urlToPage url =
    case url.fragment of
        Nothing ->
            Home

        Just "" ->
            Home

        Just fragment ->
            case String.split "/" fragment of
                [ "post", slug ] ->
                    PostView slug Nothing

                [ "tag", tag ] ->
                    TagView tag

                [ "search" ] ->
                    Search

                _ ->
                    NotFound

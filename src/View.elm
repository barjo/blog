module View exposing (view)

{-| All views for the blog: layout, pages, and components.
-}

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Icon
import Post exposing (Post)
import Render
import Route exposing (Page(..))
import Search
import Set exposing (Set)
import Theme exposing (Theme(..))


type alias Config msg =
    { toggleTheme : msg
    , searchInput : String -> msg
    }


type alias Model a =
    { a
        | page : Page
        , posts : List Post
        , error : Maybe String
        , theme : Theme
        , searchQuery : String
    }


{-| Render the full document for a given model.
-}
view : Config msg -> Model a -> Browser.Document msg
view config model =
    { title = titleFor model
    , body =
        [ Theme.codeStyle model.theme
        , viewHeader config.toggleTheme model.theme
        , viewError model.error
        , main_ []
            [ div [ class "container" ]
                [ viewPage config model ]
            ]
        , viewFooter
        ]
    }



-- Layout


viewHeader : msg -> Theme -> Html msg
viewHeader toggleThemeMsg theme =
    header [ class "container" ]
        [ nav []
            [ ul []
                [ li []
                    [ a [ href "#", class "site-title" ]
                        [ span [ class "title-prefix" ] [ text "Confession" ]
                        , span [ class "title-of" ] [ text " of a " ]
                        , span [ class "title-name" ] [ text "Barjo" ]
                        ]
                    ]
                ]
            , ul []
                [ li []
                    [ a [ href "#search", attribute "aria-label" "Search" ]
                        [ Icon.search ]
                    ]
                , li []
                    [ a [ href "https://github.com/barjo", target "_blank", attribute "aria-label" "GitHub" ]
                        [ Icon.github ]
                    ]
                , li []
                    [ a [ href "https://bsky.app/profile/barjo.bsky.social", target "_blank", attribute "aria-label" "Bluesky" ]
                        [ Icon.bluesky ]
                    ]
                , li []
                    [ a [ href "https://www.linkedin.com/in/jonathanbardin", target "_blank", attribute "aria-label" "LinkedIn" ]
                        [ Icon.linkedin ]
                    ]
                , li []
                    [ button [ class "theme-toggle", onClick toggleThemeMsg, attribute "aria-label" "Toggle theme" ]
                        [ Theme.icon theme ]
                    ]
                ]
            ]
        ]


viewFooter : Html msg
viewFooter =
    footer [ class "container" ]
        [ small []
            [ text "Powered by "
            , a [ href "https://elm-lang.org", target "_blank" ] [ text "Elm" ]
            , text " & "
            , a [ href "https://picocss.com", target "_blank" ] [ text "Pico CSS" ]
            ]
        ]


viewError : Maybe String -> Html msg
viewError maybeErr =
    case maybeErr of
        Just err ->
            div [ class "container" ]
                [ div [ class "error" ] [ text err ] ]

        Nothing ->
            text ""



-- Pages


viewPage : Config msg -> Model a -> Html msg
viewPage config model =
    case model.page of
        Home ->
            viewHome model.posts

        TagView tag ->
            viewTagPage model.posts tag

        PostView slug content ->
            viewPostPage model.posts slug content

        Search ->
            viewSearchPage config.searchInput model.searchQuery model.posts

        NotFound ->
            viewNotFound


viewHome : List Post -> Html msg
viewHome posts =
    case posts of
        [] ->
            article [] [ loading ]

        featured :: otherPosts ->
            div []
                [ viewFeaturedPost featured
                , posts |> List.concatMap .tags |> Set.fromList |> viewAllTags
                , viewPostList otherPosts
                ]


viewTagPage : List Post -> String -> Html msg
viewTagPage posts tag =
    let
        filtered =
            List.filter (\p -> List.member tag p.tags) posts
    in
    article []
        ([ backLink
         , h1 [] [ text ("#" ++ tag) ]
         ]
            ++ (if List.isEmpty filtered then
                    [ p [] [ text "No posts with this tag." ] ]

                else
                    List.map viewPostCard filtered
               )
        )


viewPostPage : List Post -> String -> Maybe String -> Html msg
viewPostPage posts slug maybeContent =
    article []
        [ Post.findBySlug slug posts |> viewMaybe viewPostHeader
        , case maybeContent of
            Just content ->
                Render.render content

            Nothing ->
                loading
        ]


viewSearchPage : (String -> msg) -> String -> List Post -> Html msg
viewSearchPage inputMsg query posts =
    let
        results =
            Search.rank query posts
    in
    article []
        ([ backLink
         , h1 [] [ text "Search" ]
         , input
            [ type_ "search"
            , id "search-input"
            , placeholder "Search posts…"
            , value query
            , onInput inputMsg
            , autofocus True
            , attribute "autocomplete" "off"
            ]
            []
         ]
            ++ (if String.isEmpty (String.trim query) then
                    [ p [ class "search-hint" ] [ text "Type to search…" ] ]

                else if List.isEmpty results then
                    [ p [ class "search-hint" ] [ text "No results found." ] ]

                else
                    List.map (\( post, _ ) -> viewPostCard post) results
               )
        )


viewNotFound : Html msg
viewNotFound =
    article []
        [ h1 [] [ text "404" ]
        , p [] [ text "Page not found." ]
        , backLink
        ]



-- Components


viewFeaturedPost : Post -> Html msg
viewFeaturedPost post =
    article [ class "featured" ]
        [ header []
            [ h1 [] [ a [ href ("#post/" ++ post.slug) ] [ text post.title ] ]
            , small [] [ time [] [ text post.date ] ]
            ]
        , p [ class "featured-desc" ] [ text post.description ]
        , div [ class "featured-footer" ]
            [ viewTags post.tags
            , a [ href ("#post/" ++ post.slug), class "nav-link" ] [ text "Read more →" ]
            ]
        ]


viewPostList : List Post -> Html msg
viewPostList posts =
    if List.isEmpty posts then
        text ""

    else
        div []
            [ h3 [ class "section-title" ] [ text "Posts" ]
            , div [] (List.map viewPostCard posts)
            ]


viewPostCard : Post -> Html msg
viewPostCard post =
    article []
        [ header []
            [ h2 [] [ a [ href ("#post/" ++ post.slug) ] [ text post.title ] ]
            , small [] [ time [] [ text post.date ] ]
            ]
        , p [] [ text post.description ]
        , viewTags post.tags
        ]


viewPostHeader : Post -> Html msg
viewPostHeader post =
    header []
        [ backLink
        , h1 [] [ text post.title ]
        , small [] [ time [] [ text post.date ] ]
        , viewTags post.tags
        ]


viewAllTags : Set String -> Html msg
viewAllTags tags =
    if Set.isEmpty tags then
        text ""

    else
        div [ class "all-tags" ]
            (tags
                |> Set.toList
                |> List.map (\tag -> a [ href ("#tag/" ++ tag), class "tag" ] [ text ("#" ++ tag) ])
            )


viewTags : List String -> Html msg
viewTags tags =
    case tags of
        [] ->
            text ""

        _ ->
            div [ class "tags" ]
                (List.map (\tag -> a [ href ("#tag/" ++ tag), class "tag" ] [ text ("#" ++ tag) ]) tags)


backLink : Html msg
backLink =
    a [ href "#", class "nav-link" ] [ text "← Back" ]



-- Helpers


loading : Html msg
loading =
    p [ attribute "aria-busy" "true" ] []


titleFor : Model a -> String
titleFor model =
    case model.page of
        Home ->
            "Confession of a Barjo"

        TagView tag ->
            "#" ++ tag ++ " — Confession of a Barjo"

        PostView slug _ ->
            model.posts
                |> Post.findBySlug slug
                |> Maybe.map .title
                |> Maybe.withDefault slug
                |> (\t -> t ++ " — Confession of a Barjo")

        Search ->
            "Search — Confession of a Barjo"

        NotFound ->
            "Not Found — Confession of a Barjo"


{-| Render a view for a Maybe value, or nothing.
-}
viewMaybe : (a -> Html msg) -> Maybe a -> Html msg
viewMaybe viewFn maybeVal =
    case maybeVal of
        Just val ->
            viewFn val

        Nothing ->
            text ""

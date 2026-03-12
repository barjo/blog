module View exposing (view)

{-| All views for the blog: layout, pages, and components.
-}

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Icon
import Post exposing (Post)
import Render
import Route exposing (Page(..))
import Set exposing (Set)
import SyntaxHighlight


type alias Model a =
    { a
        | page : Page
        , posts : List Post
        , error : Maybe String
    }


{-| Render the full document for a given model.
-}
view : Model a -> Browser.Document msg
view model =
    { title = titleFor model
    , body =
        [ SyntaxHighlight.useTheme SyntaxHighlight.monokai
        , viewHeader
        , viewError model.error
        , main_ []
            [ div [ class "container" ]
                [ viewPage model.page model.posts ]
            ]
        , viewFooter
        ]
    }



-- Layout


viewHeader : Html msg
viewHeader =
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
                    [ a [ href "https://github.com/barjo", target "_blank", attribute "aria-label" "GitHub" ]
                        [ Icon.github ]
                    ]
                , li []
                    [ a [ href "https://www.linkedin.com/in/jonathanbardin", target "_blank", attribute "aria-label" "LinkedIn" ]
                        [ Icon.linkedin ]
                    ]
                , li []
                    [ Html.node "theme-toggle" [] [] ]
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


viewPage : Page -> List Post -> Html msg
viewPage page posts =
    case page of
        Home ->
            viewHome posts

        TagView tag ->
            viewTagPage posts tag

        PostView slug content ->
            viewPostPage posts slug content

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

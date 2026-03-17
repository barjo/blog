port module Main exposing (main)

{-| Blog entry point. Wires init, update and view together.
-}

import Browser
import Browser.Navigation as Nav
import Http
import Post exposing (Post)
import Route exposing (Page(..))
import Theme exposing (Theme)
import Url
import View



-- Ports


port saveTheme : String -> Cmd msg



-- Types


type alias Flags =
    { theme : String }


type alias Model =
    { key : Nav.Key
    , page : Page
    , posts : List Post
    , error : Maybe String
    , theme : Theme
    }


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotIndex (Result Http.Error (List Post))
    | GotPost String (Result Http.Error String)
    | ToggleTheme



-- Main


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = View.view ToggleTheme
        , update = update
        , subscriptions = \_ -> Sub.none
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        page =
            Route.urlToPage url
    in
    ( { key = key, page = page, posts = [], error = Nothing, theme = Theme.fromString flags.theme }
    , Cmd.batch
        [ Post.fetchIndex GotIndex
        , case page of
            PostView slug _ ->
                Post.fetchPost slug (GotPost slug)

            _ ->
                Cmd.none
        ]
    )



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked (Browser.Internal url) ->
            ( model, Nav.pushUrl model.key (Url.toString url) )

        LinkClicked (Browser.External href) ->
            ( model, Nav.load href )

        UrlChanged url ->
            let
                page =
                    Route.urlToPage url
            in
            ( { model | page = page, error = Nothing }
            , case page of
                PostView slug _ ->
                    Post.fetchPost slug (GotPost slug)

                _ ->
                    Cmd.none
            )

        GotIndex (Ok posts) ->
            ( { model | posts = posts, error = Nothing }, Cmd.none )

        GotIndex (Err err) ->
            ( { model | error = Just (httpErrorToString err) }, Cmd.none )

        GotPost slug (Ok content) ->
            ( { model | page = PostView slug (Just content), error = Nothing }, Cmd.none )

        GotPost _ (Err err) ->
            ( { model | error = Just (httpErrorToString err) }, Cmd.none )

        ToggleTheme ->
            let
                next =
                    Theme.toggle model.theme
            in
            ( { model | theme = next }, saveTheme (Theme.toString next) )



-- Helpers


httpErrorToString : Http.Error -> String
httpErrorToString err =
    case err of
        Http.NetworkError ->
            "Network error — are you offline?"

        _ ->
            "Something went wrong."

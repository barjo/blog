module Main exposing (main)

{-| Blog entry point. Wires init, update and view together.
-}

import Browser
import Browser.Navigation as Nav
import Http
import Post exposing (Post)
import Route exposing (Page(..))
import Url
import View



-- Types


type alias Model =
    { key : Nav.Key
    , page : Page
    , posts : List Post
    , error : Maybe String
    }


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotIndex (Result Http.Error (List Post))
    | GotPost String (Result Http.Error String)



-- Main


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = View.view
        , update = update
        , subscriptions = \_ -> Sub.none
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    let
        page =
            Route.urlToPage url
    in
    ( { key = key, page = page, posts = [], error = Nothing }
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



-- Helpers


httpErrorToString : Http.Error -> String
httpErrorToString err =
    case err of
        Http.NetworkError ->
            "Network error — are you offline?"

        _ ->
            "Something went wrong."

port module Main exposing (main)

{-| Blog entry point. Wires init, update and view together.
-}

import Browser
import Browser.Dom
import Browser.Events
import Browser.Navigation as Nav
import Http
import Json.Decode as Decode
import Post exposing (Post)
import Route exposing (Page(..))
import Task
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
    , searchQuery : String
    , easterEdProgress : Int
    }


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotIndex (Result Http.Error (List Post))
    | GotPost String (Result Http.Error String)
    | ToggleTheme
    | OpenSearch
    | GoHome
    | SearchInput String
    | KeyDown String
    | NoOp



-- Main


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view =
            View.view
                { toggleTheme = ToggleTheme
                , searchInput = SearchInput
                }
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        page =
            Route.urlToPage url
    in
    ( { key = key
      , page = page
      , posts = []
      , error = Nothing
      , theme = Theme.fromString flags.theme
      , searchQuery = ""
      , easterEdProgress = 0
      }
    , Cmd.batch
        [ Post.fetchIndex GotIndex
        , case page of
            PostView slug _ ->
                Post.fetchPost slug (GotPost slug)

            _ ->
                Cmd.none
        ]
    )



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions _ =
    Browser.Events.onKeyDown
        (Decode.map4 (\key ctrl meta tag -> ( key, ctrl || meta, tag ))
            (Decode.field "key" Decode.string)
            (Decode.field "ctrlKey" Decode.bool)
            (Decode.field "metaKey" Decode.bool)
            (Decode.at [ "target", "tagName" ] Decode.string)
            |> Decode.andThen
                (\( key, mod, tag ) ->
                    if mod && key == "k" then
                        Decode.succeed OpenSearch

                    else if key == "Escape" then
                        Decode.succeed GoHome

                    else if tag /= "INPUT" && (key == "e" || key == "d") then
                        Decode.succeed (KeyDown key)

                    else
                        Decode.fail ""
                )
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
            ( { model | page = page, error = Nothing, searchQuery = "" }
            , case page of
                PostView slug _ ->
                    Post.fetchPost slug (GotPost slug)

                Search ->
                    Task.attempt (\_ -> NoOp) (Browser.Dom.focus "search-input")

                _ ->
                    Cmd.none
            )

        GotIndex (Ok posts) ->
            ( { model | posts = posts, error = Nothing }, Cmd.none )

        GotIndex (Err err) ->
            ( { model | error = Just (httpErrorToString err) }, Cmd.none )

        GotPost slug (Ok content) ->
            ( { model | page = PostView slug (Just content), error = Nothing }, Cmd.none )

        GotPost _ (Err _) ->
            ( { model | page = NotFound }, Cmd.none )

        ToggleTheme ->
            let
                next =
                    Theme.toggle model.theme
            in
            ( { model | theme = next }, saveTheme (Theme.toString next) )

        OpenSearch ->
            ( model, Nav.pushUrl model.key "#search" )

        GoHome ->
            ( model, Nav.pushUrl model.key "#" )

        SearchInput query ->
            ( { model | searchQuery = query }, Cmd.none )

        KeyDown key ->
            if key == "e" then
                ( { model | easterEdProgress = 1 }, Cmd.none )

            else if key == "d" && model.easterEdProgress == 1 then
                ( { model | theme = Theme.Radical, easterEdProgress = 0 }
                , saveTheme (Theme.toString Theme.Radical)
                )

            else
                ( { model | easterEdProgress = 0 }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )



-- Helpers


httpErrorToString : Http.Error -> String
httpErrorToString err =
    case err of
        Http.NetworkError ->
            "Network error — are you offline?"

        _ ->
            "Something went wrong."

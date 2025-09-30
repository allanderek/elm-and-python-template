module Route exposing
    ( Route(..)
    , googleOAuthPath
    , href
    , parse
    , unparse
    )

import Html
import Html.Attributes
import Url
import Url.Builder
import Url.Parser as Parser exposing ((</>))


googleOAuthPath : String
googleOAuthPath =
    "/api/auth/google/login"


type Route
    = Home
    | Login
    | Register
    | Profile
    | Feedback
    | NotFound


appPrefix : String
appPrefix =
    "app"


parse : Url.Url -> Route
parse url =
    let
        routeParser : Parser.Parser (Route -> b) b
        routeParser =
            Parser.oneOf
                [ Parser.top |> Parser.map Home
                , Parser.s "api"
                    </> Parser.s "auth"
                    </> Parser.s "google"
                    </> Parser.s "callback"
                    |> Parser.map Home
                , Parser.s appPrefix </> appParser
                ]

        appParser : Parser.Parser (Route -> b) b
        appParser =
            Parser.oneOf
                [ Parser.top |> Parser.map Home
                , Parser.s "login" |> Parser.map Login
                , Parser.s "register" |> Parser.map Register
                , Parser.s "profile" |> Parser.map Profile
                , Parser.s "feedback" |> Parser.map Feedback
                , Parser.s "not-found" |> Parser.map NotFound
                ]
    in
    url
        |> Parser.parse routeParser
        |> Maybe.withDefault NotFound


href : Route -> Html.Attribute msg
href route =
    Html.Attributes.href (unparse route)


unparse : Route -> String
unparse route =
    let
        parts : List String
        parts =
            case route of
                Home ->
                    []

                Login ->
                    [ "login" ]

                Register ->
                    [ "register" ]

                Profile ->
                    [ "profile" ]

                Feedback ->
                    [ "feedback" ]

                NotFound ->
                    [ "not-found" ]
    in
    Url.Builder.absolute (appPrefix :: parts) []

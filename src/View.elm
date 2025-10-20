module View exposing (application)

import AppDetails
import Browser
import Components.Page exposing (Page)
import Helpers.Http
import Html exposing (Html)
import Model exposing (Model)
import Msg exposing (Msg)
import Pages.Feedback
import Pages.Login
import Pages.Profile
import Pages.Register
import Route


application : Model key -> Browser.Document Msg
application model =
    let
        navigationBar : Html Msg
        navigationBar =
            Html.aside []
                [ Html.nav []
                    [ Html.ul []
                        [ Html.li []
                            [ Html.a [ Route.href Route.Home ]
                                [ Html.text "Home" ]
                            ]
                        , Html.li []
                            [ case Helpers.Http.toMaybe model.userStatus of
                                Just _ ->
                                    Html.a [ Route.href Route.Profile ]
                                        [ Html.text "Profile" ]

                                Nothing ->
                                    Html.a [ Route.href Route.Login ]
                                        [ Html.text "Login/Register" ]
                            ]
                        , Html.li []
                            [ Html.a
                                [ Route.href Route.Feedback ]
                                [ Html.text "Feedback" ]
                            ]
                        ]
                    ]
                ]

        body : Page Msg
        body =
            case model.route of
                Route.Home ->
                    { title = "Home"
                    , body = [ Html.text "Welcome to the Home Page!" ]
                    }

                Route.Login ->
                    Pages.Login.view model

                Route.Register ->
                    Pages.Register.view model

                Route.Profile ->
                    Pages.Profile.view model

                Route.Feedback ->
                    Pages.Feedback.view model

                Route.NotFound ->
                    { title = "Not found"
                    , body = [ Html.text "The page you were looking for has not been found." ]
                    }
    in
    { title =
        case model.debugMode of
            False ->
                AppDetails.title

            True ->
                String.append "DEBUG - " AppDetails.title
    , body = [ navigationBar, Components.Page.view body ]
    }

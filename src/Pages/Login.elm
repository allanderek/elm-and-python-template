module Pages.Login exposing
    ( loginWithGoogle
    , view
    , viewForm
    )

import Components.Page exposing (Page)
import Helpers.Http
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import Model exposing (Model)
import Msg exposing (Msg)
import Route
import Types.Login


view : Model key -> Page Msg
view model =
    let
        body : List (Html Msg)
        body =
            case Helpers.Http.toMaybe model.userStatus of
                Just user ->
                    [ Html.p []
                        [ Html.text "You are already logged in as "
                        , Html.text user.username
                        , Html.text "."
                        ]
                    , Html.button
                        [ Events.onClick Msg.Logout ]
                        [ Html.text "Logout" ]
                    ]

                Nothing ->
                    viewForm model
    in
    { title = "Login"
    , body = body
    }


viewForm : Model key -> List (Html Msg)
viewForm model =
    let
        isSubmitting : Bool
        isSubmitting =
            Helpers.Http.isInflight model.userStatus

        submitDisabled : Bool
        submitDisabled =
            isSubmitting || not (Types.Login.isValidForm model.loginForm)
    in
    [ Html.p []
        [ Html.text "Please log in to access your ..." ]
    , Html.form
        [ Events.onSubmit Msg.LoginSubmit ]
        [ Html.div []
            [ Html.label [ Attributes.for "username" ]
                [ Html.text "Username:" ]
            , Html.input
                [ Attributes.type_ "text"
                , Attributes.id "username"
                , Attributes.value model.loginForm.username
                , Attributes.disabled isSubmitting
                , Events.onInput (Msg.UpdateLoginForm << Msg.LoginUsernameInput)
                ]
                []
            ]
        , Html.div []
            [ Html.label [ Attributes.for "password" ]
                [ Html.text "Password:" ]
            , Html.input
                [ Attributes.type_ "password"
                , Attributes.id "password"
                , Attributes.value model.loginForm.password
                , Attributes.disabled isSubmitting
                , Events.onInput (Msg.UpdateLoginForm << Msg.LoginPasswordInput)
                ]
                []
            ]
        , Html.div []
            [ Html.button
                [ Attributes.type_ "submit"
                , Attributes.disabled submitDisabled
                ]
                [ Html.text "Login" ]
            ]
        ]
    , Html.p []
        [ Html.text "Do not yet have an account? "
        , Html.a [ Route.href Route.Register ]
            [ Html.text "Register here." ]
        ]
    , loginWithGoogle
    ]


loginWithGoogle : Html msg
loginWithGoogle =
    Html.p []
        [ Html.text "Or you can "
        , Html.a
            [ Attributes.href Route.googleOAuthPath ]
            [ Html.text "login with Google" ]
        ]

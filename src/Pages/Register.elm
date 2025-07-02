module Pages.Register exposing (view)

import Components.Page exposing (Page)
import Helpers.Http
import Html
import Html.Attributes as Attributes
import Html.Events as Events
import Model exposing (Model)
import Msg exposing (Msg)
import Route
import Types.Register


view : Model key -> Page Msg
view model =
    case Helpers.Http.toMaybe model.userStatus of
        Just user ->
            { title = "Register"
            , body =
                [ Html.p []
                    [ Html.text "You are already logged in as "
                    , Html.text user.username
                    , Html.text ". You cannot register a new account while logged in."
                    ]
                , Html.button
                    [ Events.onClick Msg.Logout ]
                    [ Html.text "Logout" ]
                ]
            }

        Nothing ->
            let
                isSubmitting : Bool
                isSubmitting =
                    Helpers.Http.isInflight model.userStatus

                submitDisabled : Bool
                submitDisabled =
                    isSubmitting || not (Types.Register.isValidForm model.registerForm)
            in
            { title = "Register"
            , body =
                [ Html.p []
                    [ Html.text "Create a new account to access your ..." ]
                , Html.form
                    [ Events.onSubmit Msg.RegisterSubmit ]
                    [ Html.div []
                        [ Html.label [ Attributes.for "username" ]
                            [ Html.text "Username:" ]
                        , Html.input
                            [ Attributes.type_ "text"
                            , Attributes.id "username"
                            , Attributes.value model.registerForm.username
                            , Attributes.disabled isSubmitting
                            , Events.onInput (Msg.UpdateRegisterForm << Msg.RegisterUsernameInput)
                            ]
                            []
                        ]
                    , Html.div []
                        [ Html.label [ Attributes.for "email" ]
                            [ Html.text "Email:" ]
                        , Html.input
                            [ Attributes.type_ "email"
                            , Attributes.id "email"
                            , Attributes.value model.registerForm.email
                            , Attributes.disabled isSubmitting
                            , Events.onInput (Msg.UpdateRegisterForm << Msg.RegisterEmailInput)
                            ]
                            []
                        ]
                    , Html.div []
                        [ Html.label [ Attributes.for "fullName" ]
                            [ Html.text "Full Name:" ]
                        , Html.input
                            [ Attributes.type_ "text"
                            , Attributes.id "fullName"
                            , Attributes.value model.registerForm.fullName
                            , Attributes.disabled isSubmitting
                            , Events.onInput (Msg.UpdateRegisterForm << Msg.RegisterFullNameInput)
                            ]
                            []
                        ]
                    , Html.div []
                        [ Html.label [ Attributes.for "password" ]
                            [ Html.text "Password:" ]
                        , Html.input
                            [ Attributes.type_ "password"
                            , Attributes.id "password"
                            , Attributes.value model.registerForm.password
                            , Attributes.disabled isSubmitting
                            , Events.onInput (Msg.UpdateRegisterForm << Msg.RegisterPasswordInput)
                            ]
                            []
                        ]
                    , Html.div []
                        [ Html.button
                            [ Attributes.type_ "submit"
                            , Attributes.disabled submitDisabled
                            ]
                            [ Html.text "Register" ]
                        ]
                    ]
                , Html.p []
                    [ Html.text "Already have an account? "
                    , Html.a [ Route.href Route.Login ]
                        [ Html.text "Login here." ]
                    ]
                ]
            }

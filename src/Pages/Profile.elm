module Pages.Profile exposing (view)

import Components.Page exposing (Page)
import Helpers.Events
import Helpers.Http
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events
import Model exposing (Model)
import Msg exposing (Msg)
import Pages.Login
import Types.ChangePassword
import Types.Profile
import Types.User exposing (User)


view : Model key -> Page Msg
view model =
    let
        viewFullnameForm : User -> Html Msg
        viewFullnameForm user =
            let
                disabled : Bool
                disabled =
                    Helpers.Http.isInflight model.profileStatus

                form : Types.Profile.Form
                form =
                    case model.profileForm of
                        Just f ->
                            f

                        Nothing ->
                            Types.Profile.initForm user
            in
            Html.form
                [ Html.Events.onSubmit (Msg.SubmitEditedProfile form)
                , Attributes.disabled disabled
                ]
                [ Html.label
                    [ Attributes.class "form-label" ]
                    [ Html.text "Full Name"
                    , Html.input
                        [ Attributes.type_ "text"
                        , Attributes.value form.fullname
                        , Attributes.name "fullname"
                        , Helpers.Events.onInputOrDisabled disabled Msg.EditProfileFullNameInput
                        , Attributes.placeholder "Full Name"
                        , Attributes.disabled disabled
                        ]
                        []
                    ]
                , Html.button
                    [ Attributes.type_ "button"
                    , Helpers.Events.onClickOrDisabled disabled Msg.CancelEditProfile
                    ]
                    [ Html.text "Cancel" ]
                , Html.button
                    [ Attributes.type_ "submit"
                    , Attributes.name "submit"
                    , Attributes.value "submit"
                    , Attributes.disabled disabled
                    ]
                    [ Html.text "Submit" ]
                ]

        viewChangePasswordForm : Html Msg
        viewChangePasswordForm =
            let
                disabled : Bool
                disabled =
                    Helpers.Http.isInflight model.changePasswordStatus

                form : Types.ChangePassword.Form
                form =
                    model.changePasswordForm
            in
            Html.form
                [ Html.Events.onSubmit Msg.SubmitChangePassword
                , Attributes.disabled disabled
                ]
                [ Html.div
                    []
                    [ Html.label
                        [ Attributes.class "form-label" ]
                        [ Html.text "Current Password (if you have one)"
                        , Html.input
                            [ Attributes.type_ "password"
                            , Attributes.value form.currentPassword
                            , Attributes.name "current_password"
                            , Helpers.Events.onInputOrDisabled disabled
                                (Msg.CurrentPasswordInput >> Msg.UpdateChangePasswordForm)
                            , Attributes.placeholder "Current Password (if you have one)"
                            , Attributes.disabled disabled
                            , Attributes.required False
                            ]
                            []
                        ]
                    ]
                , Html.div
                    []
                    [ Html.label
                        [ Attributes.class "form-label" ]
                        [ Html.text "New Password"
                        , Html.input
                            [ Attributes.type_ "password"
                            , Attributes.value form.newPassword
                            , Attributes.name "new_password"
                            , Helpers.Events.onInputOrDisabled disabled
                                (Msg.NewPasswordInput >> Msg.UpdateChangePasswordForm)
                            , Attributes.placeholder "New Password"
                            , Attributes.disabled disabled
                            , Attributes.required True
                            ]
                            []
                        ]
                    ]
                , Html.div
                    []
                    [ Html.label
                        [ Attributes.class "form-label" ]
                        [ Html.text "Confirm New Password (optional)"
                        , Html.input
                            [ Attributes.type_ "password"
                            , Attributes.value form.confirmPassword
                            , Attributes.name "confirm_password"
                            , Helpers.Events.onInputOrDisabled disabled
                                (Msg.ConfirmPasswordInput >> Msg.UpdateChangePasswordForm)
                            , Attributes.placeholder "Confirm New Password (optional)"
                            , Attributes.disabled disabled
                            , Attributes.required False
                            ]
                            []
                        ]
                    ]
                , Html.button
                    [ Attributes.type_ "button"
                    , Helpers.Events.onClickOrDisabled disabled Msg.CancelEditPassword
                    ]
                    [ Html.text "Cancel" ]
                , Html.button
                    [ Attributes.type_ "submit"
                    , Attributes.name "submit"
                    , Attributes.value "submit"
                    , Attributes.disabled (disabled || not (Types.ChangePassword.isValidForm form))
                    ]
                    [ Html.text "Change Password" ]
                ]

        body : List (Html Msg)
        body =
            case Helpers.Http.toMaybe model.userStatus of
                Just user ->
                    [ Html.dl
                        []
                        [ Html.dt
                            []
                            [ Html.text "Username" ]
                        , Html.dd
                            []
                            [ Html.text user.username ]
                        , Html.dt
                            []
                            [ Html.text "Name" ]
                        , Html.dd
                            []
                            (case model.editingProfile of
                                False ->
                                    [ Html.text user.fullname
                                    , Html.button
                                        [ Attributes.class "edit-profile-button"
                                        , Html.Events.onClick Msg.EditProfile
                                        ]
                                        [ Html.text "Edit" ]
                                    ]

                                True ->
                                    [ viewFullnameForm user ]
                            )
                        , Html.dt
                            []
                            [ Html.text "Password" ]
                        , Html.dd
                            []
                            (case model.editingPassword of
                                False ->
                                    [ Html.button
                                        [ Attributes.class "change-password-button"
                                        , Html.Events.onClick Msg.EditPassword
                                        ]
                                        [ Html.text "Change Password" ]
                                    ]

                                True ->
                                    [ viewChangePasswordForm ]
                            )
                        , Html.dt
                            []
                            [ Html.text "Logout" ]
                        , Html.dd
                            []
                            [ Html.button
                                [ Attributes.class "logout-button"
                                , Html.Events.onClick Msg.Logout
                                ]
                                [ Html.text "Logout" ]
                            ]
                        ]
                    ]

                Nothing ->
                    Pages.Login.viewForm model
    in
    { title = "Profile"
    , body = body
    }

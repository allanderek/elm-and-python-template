module Pages.Feedback exposing
    ( view
    , viewForm
    )

import Components.Page exposing (Page)
import Components.StatusError
import Helpers.Classes
import Helpers.Http
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import Html.Extra
import Http
import Model exposing (Model)
import Msg exposing (Msg)
import Types.Button
import Types.User exposing (User)
import Types.UserFeedback


view : Model key -> Page Msg
view model =
    let
        mUser : Maybe User
        mUser =
            Helpers.Http.toMaybe model.userStatus
    in
    { title = "Feedback"
    , body =
        case model.userFeedbackStatus of
            Helpers.Http.Inflight ->
                viewForm True Nothing mUser model.userFeedbackForm

            Helpers.Http.Failed error ->
                viewForm False (Just error) mUser model.userFeedbackForm

            Helpers.Http.Ready ->
                viewForm False Nothing mUser model.userFeedbackForm

            Helpers.Http.Succeeded () ->
                [ Html.text "Thank you for your feedback!"
                , Html.button
                    [ Attributes.type_ "button"
                    , Events.onClick Msg.ResetUserFeedbackForm
                    , Types.Button.variantClass Types.Button.Primary
                    , Types.Button.kindClass Types.Button.Interface
                    ]
                    [ Html.text "Submit another feedback" ]
                ]
    }


viewForm : Bool -> Maybe Http.Error -> Maybe User -> Types.UserFeedback.Form -> List (Html Msg)
viewForm isSubmitting mError mUser form =
    let
        validForm : Bool
        validForm =
            Types.UserFeedback.isValidForm form

        submitDisabled : Bool
        submitDisabled =
            isSubmitting || not validForm

        emailExplanation : Html msg
        emailExplanation =
            Html.p
                [ Attributes.class "email-explanation" ]
                [ Html.text "Your email is optional, but it helps us to contact you if we need more information about your feedback."
                ]

        userExplanation : Html msg
        userExplanation =
            case mUser of
                Nothing ->
                    Html.Extra.nothing

                Just user ->
                    Html.p
                        [ Attributes.class "user-explanation" ]
                        [ Html.text "You are logged in as "
                        , Html.text user.username
                        , Html.text ". Your feedback will be associated with this account. If you would rather submit anonymously please either logout first, or use an incognito window. "
                        , Html.text "If there is an email address associated with your account we may use this to contact you to follow up on your feedback."
                        ]
    in
    [ Html.p []
        [ Html.text "Please enter your feedback ..." ]
    , Html.form
        [ Events.onSubmit Msg.SubmitUserFeedback ]
        [ Html.div
            [ Attributes.class "form-group" ]
            [ emailExplanation
            , userExplanation
            , Html.label
                [ Attributes.for "email-input"
                , Helpers.Classes.optional True
                ]
                [ Html.text "Email" ]
            , Html.input
                [ Attributes.type_ "email"
                , Attributes.id "email-input"
                , Attributes.value form.email
                , Attributes.disabled isSubmitting
                , Msg.UserFeedbackEmailInput
                    >> Msg.UpdateUserFeedbackForm
                    |> Events.onInput
                ]
                []
            ]
        , Html.div
            [ Attributes.class "form-group" ]
            [ Html.label
                [ Attributes.for "comments-input" ]
                [ Html.text "Comments" ]
            , Html.textarea
                [ Attributes.id "comments-input"
                , Attributes.value form.comments
                , Attributes.disabled isSubmitting
                , Msg.UserFeedbackCommentsInput
                    >> Msg.UpdateUserFeedbackForm
                    |> Events.onInput
                ]
                []
            ]
        , Maybe.map Components.StatusError.viewError mError
            |> Maybe.withDefault Html.Extra.nothing
        , Html.div
            [ Attributes.class "form-actions" ]
            [ Html.button
                [ Attributes.type_ "submit"
                , Attributes.disabled submitDisabled
                , Types.Button.variantClass Types.Button.Primary
                , Types.Button.kindClass Types.Button.Form
                ]
                [ Html.text "Submit" ]
            ]
        ]
    ]

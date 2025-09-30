module Perform exposing (perform)

import Browser.Navigation
import Effect exposing (Effect)
import Http
import Json.Decode as Decode exposing (Decoder)
import Msg exposing (Msg)
import Ports
import Task
import Time
import TimeZone
import Types.Data
import Types.Login
import Types.Profile
import Types.Register
import Types.User exposing (User)
import Types.UserFeedback


apiPrefix : String
apiPrefix =
    "/api"


apiUrl : List String -> String
apiUrl path =
    String.join "/" (apiPrefix :: path)


perform : { a | navigationKey : Browser.Navigation.Key } -> Effect -> Cmd Msg
perform model effect =
    case effect of
        Effect.None ->
            Cmd.none

        Effect.Batch effects ->
            List.map (perform model) effects
                |> Cmd.batch

        Effect.PushUrl url ->
            Browser.Navigation.pushUrl model.navigationKey url

        Effect.LoadUrl url ->
            Browser.Navigation.load url

        Effect.Reload ->
            Browser.Navigation.reload

        Effect.SetLocalStorage key value ->
            Ports.setLocalStorage { key = key, value = value }

        Effect.ClearLocalStorage key ->
            Ports.clearLocalStorage key

        Effect.NativeAlert message ->
            Ports.nativeAlert message

        Effect.GetTimeZone ->
            Task.attempt Msg.GetTimeZone TimeZone.getZone

        Effect.LegacyGetTimeZone ->
            Task.perform Msg.LegacyGetTimeZone Time.here

        Effect.SubmitRegister form ->
            let
                url : String
                url =
                    apiUrl [ "register" ]

                body : Http.Body
                body =
                    form
                        |> Types.Register.encodeForm
                        |> Http.jsonBody

                decoder : Decoder User
                decoder =
                    Types.User.decoder
                        |> Decode.field "user"
            in
            Http.post
                { url = url
                , body = body
                , expect = Http.expectJson Msg.RegisterSubmitResponse decoder
                }

        Effect.SubmitLogin form ->
            let
                url : String
                url =
                    apiUrl [ "login" ]

                body : Http.Body
                body =
                    form
                        |> Types.Login.encodeForm
                        |> Http.jsonBody

                decoder : Decoder User
                decoder =
                    Types.User.decoder
                        |> Decode.field "user"
            in
            Http.post
                { url = url
                , body = body
                , expect = Http.expectJson Msg.LoginSubmitResponse decoder
                }

        Effect.SubmitLogout ->
            Http.post
                { url = apiUrl [ "logout" ]
                , body = Http.emptyBody
                , expect = Http.expectWhatever Msg.LogoutResponse
                }

        Effect.SubmitProfile form ->
            let
                decoder : Decoder User
                decoder =
                    Types.User.decoder
            in
            Http.post
                { url = apiUrl [ "profile" ]
                , body =
                    form
                        |> Types.Profile.encodeForm
                        |> Http.jsonBody
                , expect = Http.expectJson Msg.SubmitEditedProfileResponse decoder
                }

        Effect.GetData data ->
            case data of
                Types.Data.None ->
                    Cmd.none

        Effect.SubmitUserFeedback form ->
            let
                url : String
                url =
                    apiUrl [ "feedback" ]

                body : Http.Body
                body =
                    form
                        |> Types.UserFeedback.encodeForm
                        |> Http.jsonBody

                decoder : Decoder ()
                decoder =
                    Decode.succeed ()
            in
            Http.post
                { url = url
                , body = body
                , expect = Http.expectJson Msg.SubmitUserFeedbackResponse decoder
                }

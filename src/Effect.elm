module Effect exposing
    ( Effect(..)
    , goto
    )

import Json.Encode
import Route exposing (Route)
import Types.ChangePassword
import Types.Data exposing (Data)
import Types.Login
import Types.Profile
import Types.Register
import Types.UserFeedback


type Effect
    = None
    | Batch (List Effect)
    | PushUrl String
    | LoadUrl String
    | Reload
    | SetLocalStorage String Json.Encode.Value
    | ClearLocalStorage String
    | NativeAlert String
    | GetTimeZone
    | LegacyGetTimeZone
    | SubmitRegister Types.Register.Form
    | SubmitLogin Types.Login.Form
    | SubmitLogout
    | SubmitProfile Types.Profile.Form
    | SubmitChangePassword Types.ChangePassword.Form
    | GetData Data
    | SubmitUserFeedback Types.UserFeedback.Form


goto : Route -> Effect
goto route =
    route
        |> Route.unparse
        |> PushUrl

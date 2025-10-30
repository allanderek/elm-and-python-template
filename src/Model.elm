module Model exposing
    ( Model
    , getFromStatusDict
    , initial
    )

import Dict exposing (Dict)
import Helpers.Http
import Route exposing (Route)
import Time
import Types.ChangePassword
import Types.Login
import Types.Profile
import Types.Register
import Types.User exposing (User)
import Types.UserFeedback
import Url exposing (Url)


type alias Model key =
    { navigationKey : key
    , debugMode : Bool
    , route : Route
    , now : Time.Posix
    , zone : Time.Zone
    , userStatus : Helpers.Http.Status User
    , loginForm : Types.Login.Form
    , registerForm : Types.Register.Form
    , editingProfile : Bool
    , profileForm : Maybe Types.Profile.Form
    , profileStatus : Helpers.Http.Status User
    , editingPassword : Bool
    , changePasswordForm : Types.ChangePassword.Form
    , changePasswordStatus : Helpers.Http.Status ()
    , userFeedbackForm : Types.UserFeedback.Form
    , userFeedbackStatus : Helpers.Http.Status ()
    }


initial : key -> Bool -> Url -> Time.Posix -> Helpers.Http.Status User -> Model key
initial key debugMode url now userStatus =
    { navigationKey = key
    , debugMode = debugMode
    , route = Route.parse url
    , now = now
    , zone = Time.utc
    , userStatus = userStatus
    , loginForm = Types.Login.emptyForm
    , registerForm = Types.Register.emptyForm
    , editingProfile = False
    , profileForm = Nothing
    , profileStatus = Helpers.Http.Ready
    , editingPassword = False
    , changePasswordForm = Types.ChangePassword.emptyForm
    , changePasswordStatus = Helpers.Http.Ready
    , userFeedbackForm = Types.UserFeedback.emptyForm
    , userFeedbackStatus = Helpers.Http.Ready
    }


getFromStatusDict : comparable -> Dict comparable (Helpers.Http.Status a) -> Maybe a
getFromStatusDict key dict =
    Dict.get key dict
        |> Maybe.withDefault Helpers.Http.Ready
        |> Helpers.Http.toMaybe

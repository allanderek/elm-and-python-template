module Model exposing
    ( Model
    , getFromStatusDict
    , initial
    )

import Dict exposing (Dict)
import Helpers.Http
import Route exposing (Route)
import Time
import Types.Login
import Types.Profile
import Types.Register
import Types.User exposing (User)
import Url exposing (Url)


type alias Model key =
    { navigationKey : key
    , route : Route
    , now : Time.Posix
    , zone : Time.Zone
    , userStatus : Helpers.Http.Status User
    , loginForm : Types.Login.Form
    , registerForm : Types.Register.Form
    , editingProfile : Bool
    , profileForm : Maybe Types.Profile.Form
    , profileStatus : Helpers.Http.Status User
    }


initial : key -> Url -> Time.Posix -> Helpers.Http.Status User -> Model key
initial key url now userStatus =
    { navigationKey = key
    , route = Route.parse url
    , now = now
    , zone = Time.utc
    , userStatus = userStatus
    , loginForm = Types.Login.emptyForm
    , registerForm = Types.Register.emptyForm
    , editingProfile = False
    , profileForm = Nothing
    , profileStatus = Helpers.Http.Ready
    }


getFromStatusDict : comparable -> Dict comparable (Helpers.Http.Status a) -> Maybe a
getFromStatusDict key dict =
    Dict.get key dict
        |> Maybe.withDefault Helpers.Http.Ready
        |> Helpers.Http.toMaybe

module Msg exposing
    ( HttpResult
    , Msg(..)
    , UpdateLoginFormMsg(..)
    , UpdateRegisterFormMsg(..)
    )

import Browser
import Http
import Json.Decode
import Time
import TimeZone
import Types.LocalStorageNotification exposing (LocalStorageNotification)
import Types.Profile
import Types.User exposing (User)
import Url


type alias HttpResult a =
    Result Http.Error a


type UpdateLoginFormMsg
    = LoginUsernameInput String
    | LoginPasswordInput String


type UpdateRegisterFormMsg
    = RegisterUsernameInput String
    | RegisterPasswordInput String
    | RegisterEmailInput String
    | RegisterFullNameInput String


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | Tick Time.Posix
    | GetTimeZone (Result TimeZone.Error ( String, Time.Zone ))
    | LegacyGetTimeZone Time.Zone
    | LocalStorageNotification (Result Json.Decode.Error LocalStorageNotification)
    | UpdateLoginForm UpdateLoginFormMsg
    | LoginSubmit
    | LoginSubmitResponse (HttpResult User)
    | Logout
    | LogoutResponse (HttpResult ())
    | EditProfile
    | CancelEditProfile
    | EditProfileFullNameInput String
    | SubmitEditedProfile Types.Profile.Form
    | SubmitEditedProfileResponse (HttpResult User)
    | RegisterSubmit
    | RegisterSubmitResponse (HttpResult User)
    | UpdateRegisterForm UpdateRegisterFormMsg

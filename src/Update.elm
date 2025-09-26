module Update exposing
    ( initRoute
    , update
    )

import Browser
import Effect exposing (Effect)
import Helpers.Http
import Helpers.List
import Model exposing (Model)
import Msg exposing (Msg)
import Return
import Route exposing (Route)
import Types.Data exposing (Data)
import Types.LocalStorageNotification
import Types.Login
import Types.Profile
import Types.Register
import Types.User exposing (User)
import Url


getData : Data -> Model key -> ( Model key, Effect )
getData data model =
    let
        newModel : Model key
        newModel =
            case data of
                Types.Data.None ->
                    model
    in
    ( newModel, Effect.GetData data )


getDataWith : Data -> ( Model key, Effect ) -> ( Model key, Effect )
getDataWith data ( model, existingEffect ) =
    Return.combine (getData data) ( model, existingEffect )


getMultipleData : List Data -> Model key -> ( Model key, Effect )
getMultipleData datas model =
    List.foldl getDataWith (Return.noEffect model) datas


getMultipleDataIf : List ( Bool, Data ) -> Model key -> ( Model key, Effect )
getMultipleDataIf datas model =
    getMultipleData (Helpers.List.filterByFirst datas) model


initRoute : Model key -> ( Model key, Effect )
initRoute model =
    case model.route of
        Route.Home ->
            Return.noEffect model

        Route.Login ->
            Return.noEffect model

        Route.Register ->
            Return.noEffect model

        Route.Profile ->
            Return.noEffect model

        Route.NotFound ->
            Return.noEffect model


logoutUser : { clearLocalStorage : Bool } -> Model key -> ( Model key, Effect )
logoutUser config model =
    -- It doesn't really matter what the result is, since even with success
    -- we're just going to reload the current page, so any updates we do here would
    -- be lost anyway. If this fails, then we could set the user status to the failure,
    -- but then that would look like you were logged-out when maybe actually you weren't.
    -- So we just ignore the result and reload the page.
    ( model
    , Effect.Batch
        [ Effect.Reload

        -- Note: This is second so that it occurs first, that is how Cmd.batch works.
        , case config.clearLocalStorage of
            True ->
                Effect.ClearLocalStorage "user"

            False ->
                Effect.None
        ]
    )


postLoginNav : Route -> Effect
postLoginNav route =
    case route of
        Route.Login ->
            Effect.goto Route.Home

        _ ->
            Effect.None


update : Msg -> Model key -> ( Model key, Effect )
update msg model =
    case msg of
        Msg.LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    let
                        urlString : String
                        urlString =
                            Url.toString url
                    in
                    case url.path == Route.googleOAuthPath of
                        True ->
                            ( model
                            , Effect.LoadUrl urlString
                            )

                        False ->
                            ( model
                            , Effect.PushUrl urlString
                            )

                Browser.External href ->
                    ( model
                    , Effect.LoadUrl href
                    )

        Msg.UrlChanged url ->
            initRoute
                { model | route = Route.parse url }

        Msg.Tick now ->
            Return.noEffect { model | now = now }

        Msg.GetTimeZone result ->
            case result of
                Err _ ->
                    ( model
                    , Effect.LegacyGetTimeZone
                    )

                Ok ( _, zone ) ->
                    Return.noEffect { model | zone = zone }

        Msg.LegacyGetTimeZone zone ->
            Return.noEffect { model | zone = zone }

        Msg.LocalStorageNotification result ->
            case result of
                Err _ ->
                    -- This could of course mean there is an error in the decoder, in normal operation it
                    -- simply means that it was a local storage key we do not care about.
                    Return.noEffect model

                Ok (Types.LocalStorageNotification.UserUpdated mNewUser) ->
                    let
                        mCurrentUser : Maybe User
                        mCurrentUser =
                            Helpers.Http.toMaybe model.userStatus
                    in
                    case ( mCurrentUser, mNewUser ) of
                        ( Just _, Nothing ) ->
                            -- The user has logged-out on a separate tab.
                            logoutUser { clearLocalStorage = False } model

                        ( Just _, Just newUser ) ->
                            -- The user has just changed something, this doesn't happen often but for example will happen
                            -- with the loginExpiration when the cookie/token is refreshed.
                            Return.noEffect { model | userStatus = Helpers.Http.Succeeded newUser }

                        ( Nothing, Just newUser ) ->
                            -- The user has been logged-in on a seperate tab
                            -- the user profile, let's just assume that this is correct.
                            ( { model | userStatus = Helpers.Http.Succeeded newUser }
                            , postLoginNav model.route
                            )

                        ( Nothing, Nothing ) ->
                            -- Unlikely, but whatever this means that the user has been logged-out but this application
                            -- already thinks the user is logged-out so nothing to do.
                            Return.noEffect model

        Msg.UpdateLoginForm updateMsg ->
            let
                form : Types.Login.Form
                form =
                    model.loginForm

                newForm : Types.Login.Form
                newForm =
                    case updateMsg of
                        Msg.LoginUsernameInput input ->
                            { form | username = input }

                        Msg.LoginPasswordInput input ->
                            { form | password = input }
            in
            Return.noEffect { model | loginForm = newForm }

        Msg.LoginSubmit ->
            case Types.Login.isValidForm model.loginForm of
                False ->
                    Return.noEffect model

                True ->
                    ( { model | userStatus = Helpers.Http.Inflight }
                    , Effect.SubmitLogin model.loginForm
                    )

        Msg.LoginSubmitResponse result ->
            ( { model | userStatus = Helpers.Http.fromResult result }
            , case result of
                Err _ ->
                    Effect.NativeAlert "Login failed. Please check your username and password."

                Ok user ->
                    Effect.Batch
                        [ postLoginNav model.route
                        , Effect.SetLocalStorage "user" (Types.User.encode user)
                        ]
            )

        Msg.Logout ->
            ( model, Effect.SubmitLogout )

        Msg.LogoutResponse result ->
            let
                clearLocalStorage : Bool
                clearLocalStorage =
                    case result of
                        Ok _ ->
                            True

                        Err _ ->
                            False
            in
            -- We don't care about the result of the logout since we're about to reload the page anyway.
            -- If the logout was successful, this will logout the user, if it failed, then the user will
            -- still be logged-in after the reload. However, we do want to clear the local storage only if
            -- the logout was successful.
            logoutUser { clearLocalStorage = clearLocalStorage } model

        Msg.EditProfile ->
            Return.noEffect { model | editingProfile = True }

        Msg.CancelEditProfile ->
            Return.noEffect { model | editingProfile = False }

        Msg.EditProfileFullNameInput input ->
            case Helpers.Http.toMaybe model.userStatus of
                Nothing ->
                    Return.noEffect model

                Just user ->
                    let
                        newForm : Maybe Types.Profile.Form
                        newForm =
                            case input == user.fullname of
                                True ->
                                    Nothing

                                False ->
                                    let
                                        form : Types.Profile.Form
                                        form =
                                            case model.profileForm of
                                                Nothing ->
                                                    Types.Profile.initForm user

                                                Just existingForm ->
                                                    existingForm
                                    in
                                    Just { form | fullname = input }
                    in
                    Return.noEffect
                        { model | profileForm = newForm }

        Msg.SubmitEditedProfile form ->
            ( { model | profileStatus = Helpers.Http.Inflight }
            , Effect.SubmitProfile form
            )

        Msg.SubmitEditedProfileResponse result ->
            ( { model
                | profileStatus = Helpers.Http.fromResult result
                , userStatus =
                    case result of
                        Ok user ->
                            Helpers.Http.Succeeded user

                        Err _ ->
                            model.userStatus
                , editingProfile =
                    case result of
                        Ok _ ->
                            False

                        Err _ ->
                            True
                , profileForm =
                    case result of
                        Ok _ ->
                            Nothing

                        Err _ ->
                            model.profileForm
              }
            , case result of
                Ok user ->
                    Effect.SetLocalStorage "user" (Types.User.encode user)

                Err _ ->
                    Effect.None
            )

        Msg.UpdateRegisterForm updateMsg ->
            let
                form : Types.Register.Form
                form =
                    model.registerForm

                newForm : Types.Register.Form
                newForm =
                    case updateMsg of
                        Msg.RegisterUsernameInput input ->
                            { form | username = input }

                        Msg.RegisterPasswordInput input ->
                            { form | password = input }

                        Msg.RegisterEmailInput input ->
                            { form | email = input }

                        Msg.RegisterFullNameInput input ->
                            { form | fullName = input }
            in
            Return.noEffect { model | registerForm = newForm }

        Msg.RegisterSubmit ->
            case Types.Register.isValidForm model.registerForm of
                False ->
                    Return.noEffect model

                True ->
                    ( { model | userStatus = Helpers.Http.Inflight }
                    , Effect.SubmitRegister model.registerForm
                    )

        Msg.RegisterSubmitResponse result ->
            ( { model | userStatus = Helpers.Http.fromResult result }
            , case result of
                Err _ ->
                    Effect.NativeAlert "Registration failed. Please check your details and try again."

                Ok user ->
                    Effect.Batch
                        [ postLoginNav model.route
                        , Effect.SetLocalStorage "user" (Types.User.encode user)
                        ]
            )

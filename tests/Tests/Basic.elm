module Tests.Basic exposing
    ( checkLoggedInFromAnotherTab
    , checkLoggedOutShownLoginForm
    )

import Effect exposing (Effect)
import Expect
import Generated.Ports
import Generated.Simulate
import Html.Attributes
import Json.Decode as Decode
import Json.Encode as Encode
import Main
import Model exposing (Model)
import Msg exposing (Msg)
import ProgramTest
import Route exposing (Route)
import Test exposing (Test)
import Test.Html.Selector as Selector
import Types.LocalStorageNotification
import Types.User exposing (User)
import Update
import View


type alias TestNavKey =
    ()


type alias TestModel =
    Model TestNavKey


type alias Url =
    String


type alias ProgramDefinition =
    ProgramTest.ProgramDefinition Main.ProgramFlags TestModel Msg Effect


createApplication : Maybe Route -> ProgramDefinition
createApplication mInitialRoute =
    let
        initialUrl : Url
        initialUrl =
            mInitialRoute
                |> Maybe.withDefault Route.Home
                |> Route.unparse
                |> String.append "https://example.com"
    in
    ProgramTest.createApplication
        { onUrlChange = Msg.UrlChanged
        , onUrlRequest = Msg.LinkClicked
        , init = Main.init
        , update = Update.update
        , view = View.application
        }
        |> ProgramTest.withBaseUrl initialUrl
        |> ProgramTest.withSimulatedEffects Generated.Simulate.simulate


loggedOutFlags : Main.ProgramFlags
loggedOutFlags =
    Encode.null


checkLoggedOutShownLoginForm : Test
checkLoggedOutShownLoginForm =
    let
        testFun : () -> Expect.Expectation
        testFun () =
            createApplication (Just Route.Profile)
                |> ProgramTest.start loggedOutFlags
                |> ProgramTest.expectViewHas
                    [ Selector.all
                        [ Selector.tag "form"
                        , Selector.containing
                            [ Selector.tag "input"
                            , Selector.attribute (Html.Attributes.type_ "text")
                            ]
                        , Selector.containing
                            [ Selector.tag "input"
                            , Selector.attribute (Html.Attributes.type_ "password")
                            ]
                        ]
                    ]
    in
    Test.test "Tests that a non-logged in user is shown the login form" testFun


checkLoggedInFromAnotherTab : Test
checkLoggedInFromAnotherTab =
    let
        subscriptions : Model TestNavKey -> ProgramTest.SimulatedSub Msg
        subscriptions _ =
            let
                localStorageChanged : ProgramTest.SimulatedSub Msg
                localStorageChanged =
                    let
                        toMessage : Encode.Value -> Msg
                        toMessage jsonValue =
                            Decode.decodeValue Types.LocalStorageNotification.decoder jsonValue
                                |> Msg.LocalStorageNotification
                    in
                    Generated.Ports.local_storage_changed toMessage
            in
            localStorageChanged

        loggedInUser : User
        loggedInUser =
            { id = 1
            , username = "user1"
            , fullname = "User One"
            , isAdmin = False
            }

        localStorageNotification : Encode.Value
        localStorageNotification =
            Encode.object
                [ ( "key", Encode.string "user" )
                , ( "newValue", Types.User.encode loggedInUser )
                ]

        testFun : () -> Expect.Expectation
        testFun () =
            createApplication (Just Route.Profile)
                |> ProgramTest.withSimulatedSubscriptions subscriptions
                |> ProgramTest.start loggedOutFlags
                |> ProgramTest.ensureViewHas
                    [ Selector.all
                        [ Selector.tag "form"
                        , Selector.containing
                            [ Selector.tag "input"
                            , Selector.attribute (Html.Attributes.type_ "text")
                            ]
                        , Selector.containing
                            [ Selector.tag "input"
                            , Selector.attribute (Html.Attributes.type_ "password")
                            ]
                        ]
                    ]
                |> ProgramTest.simulateIncomingPort "local_storage_changed" localStorageNotification
                |> ProgramTest.expectViewHas
                    [ Selector.all
                        [ Selector.tag "dt"
                        , Selector.text "Username"
                        ]
                    , Selector.all
                        [ Selector.tag "dd"
                        , Selector.text loggedInUser.username
                        ]
                    ]
    in
    Test.test "Tests that the user can be logged-in from another tab." testFun

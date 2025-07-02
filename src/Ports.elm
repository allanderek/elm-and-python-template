port module Ports exposing
    ( clearLocalStorage
    , local_storage_changed
    , nativeAlert
    , setLocalStorage
    )

import Json.Encode


port local_storage_changed : (Json.Encode.Value -> msg) -> Sub msg


port native_alert : Json.Encode.Value -> Cmd msg


nativeAlert : String -> Cmd msg
nativeAlert message =
    Json.Encode.string message
        |> native_alert


port set_local_storage : Json.Encode.Value -> Cmd msg


setLocalStorage : { key : String, value : Json.Encode.Value } -> Cmd msg
setLocalStorage { key, value } =
    [ ( "key", Json.Encode.string key )
    , ( "value", value )
    ]
        |> Json.Encode.object
        |> set_local_storage


port clear_local_storage : Json.Encode.Value -> Cmd msg


clearLocalStorage : String -> Cmd msg
clearLocalStorage key =
    Json.Encode.string key
        |> clear_local_storage

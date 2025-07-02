module Types.Register exposing
    ( Form
    , emptyForm
    , encodeForm
    , isValidForm
    )

import Json.Encode as Encode


type alias Form =
    { username : String
    , password : String
    , email : String
    , fullName : String
    }


emptyForm : Form
emptyForm =
    { username = ""
    , password = ""
    , email = ""
    , fullName = ""
    }


isValidForm : Form -> Bool
isValidForm form =
    (String.length form.username > 0)
        && (String.length form.password > 0)
        && (String.length form.email > 0)
        && (String.length form.fullName > 0)


encodeForm : Form -> Encode.Value
encodeForm form =
    Encode.object
        [ ( "username", Encode.string form.username )
        , ( "password", Encode.string form.password )
        , ( "email", Encode.string form.email )
        , ( "fullname", Encode.string form.fullName )
        ]


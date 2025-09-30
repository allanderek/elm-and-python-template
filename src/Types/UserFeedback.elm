module Types.UserFeedback exposing
    ( Form
    , emptyForm
    , encodeForm
    , isValidForm
    )

import Json.Encode as Encode


type alias Form =
    { email : String
    , comments : String
    }


emptyForm : Form
emptyForm =
    { email = ""
    , comments = ""
    }


encodeForm : Form -> Encode.Value
encodeForm form =
    Encode.object
        [ ( "email", Encode.string form.email )
        , ( "comments", Encode.string form.comments )
        ]


isValidForm : Form -> Bool
isValidForm form =
    (String.length form.comments > 0)
        && (String.length form.comments <= 5000)

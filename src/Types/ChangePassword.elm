module Types.ChangePassword exposing
    ( Form
    , emptyForm
    , encodeForm
    , isValidForm
    )

import Json.Encode
import String.Extra


type alias Form =
    { currentPassword : String
    , newPassword : String
    , confirmPassword : String
    }


emptyForm : Form
emptyForm =
    { currentPassword = ""
    , newPassword = ""
    , confirmPassword = ""
    }


isValidForm : Form -> Bool
isValidForm form =
    let
        newPasswordValid : Bool
        newPasswordValid =
            not (String.Extra.isBlank form.newPassword)

        confirmPasswordValid : Bool
        confirmPasswordValid =
            -- Confirm password can be blank, but if it's not blank, it must match new password
            String.Extra.isBlank form.confirmPassword
                || (form.confirmPassword == form.newPassword)
    in
    newPasswordValid && confirmPasswordValid


encodeForm : Form -> Json.Encode.Value
encodeForm form =
    let
        confirmPassword : String
        confirmPassword =
            case String.Extra.isBlank form.confirmPassword of
                True ->
                    form.newPassword

                False ->
                    form.confirmPassword
    in
    Json.Encode.object
        [ ( "current_password", Json.Encode.string form.currentPassword )
        , ( "new_password", Json.Encode.string form.newPassword )
        , ( "confirm_password", Json.Encode.string confirmPassword )
        ]

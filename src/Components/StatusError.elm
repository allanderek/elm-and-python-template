module Components.StatusError exposing
    ( view
    , viewError
    )

import Helpers.Http
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Extra
import Http


view : Helpers.Http.Status a -> Html msg
view status =
    case status of
        Helpers.Http.Failed error ->
            viewError error

        Helpers.Http.Ready ->
            Html.Extra.nothing

        Helpers.Http.Inflight ->
            Html.Extra.nothing

        Helpers.Http.Succeeded _ ->
            Html.Extra.nothing


viewError : Http.Error -> Html msg
viewError error =
    Html.div
        [ Attributes.class "status-error" ]
        -- TODO: Actually explain the error
        [ Html.text "An error occurred: " ]

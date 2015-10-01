module Battleship where

-- Core
import Dict
import Array
import String
-- Evan
import Html
import Html.Attributes
import Html.Events
import StartApp.Simple as StartApp
-- 3rd Party
-- Battleship
import Ship

---- MAIN ----
main =
    StartApp.start { model = defaultModel, view = view, update = update }

---- MODEL ----
defaultModel : Model
defaultModel =
    { state = Setup
    , player = defaultPlayer
    , computer = defaultComputer
    }
-- Model
type alias Model =
    { state : State
    , player : Player
    , computer : Player -- Should this be a maybe?
    }
-- State
type State
    = Setup
    | Play
    | GameOver

---- VIEW ----
view : Signal.Address Action -> Model -> Html.Html
view address model =
    case model.state of
        Setup -> setupControlsView address model.player
        Play ->
            Html.div []
                [ Html.div [] [ Html.text (toString model) ] ]
        GameOver ->
            Html.div []
                [ Html.div [] [ Html.text (toString model) ] ]


setupControlsView : Signal.Address Action -> Player -> Html.Html
setupControlsView address player =
    let theHtml = player.ships
        |> Dict.toList
        |> List.map (\ (shipId, ship) -> shipFieldView address shipId ship)
    in
    Html.div [] (theHtml ++ [Html.text (toString player.ships)])

--Depending on the Action render the proper html input.
shipFieldView : Signal.Address Action -> Int -> Ship -> Html.Html
shipFieldView address shipId theShip =
    if not theShip.added then
        Html.div []
        [ Html.input -- Ship Row Input
            [ Html.Attributes.value (toString theShip.row)
            , Html.Events.on "input" Html.Events.targetValue (Signal.message address << SetupRowField shipId)
            ]
            []
        , Html.input -- Ship Column Input
            [ Html.Attributes.value (toString theShip.column)
            , Html.Events.on "input" Html.Events.targetValue (Signal.message address << SetupColumnField shipId)
            ]
            []
        , Html.input -- Ship Orientation
            [ Html.Attributes.type' "radio"
            , Html.Attributes.checked (theShip.orientation == Horizontal)
            , Html.Events.onClick address (SetupOrientationField shipId)
            ]
            []
        , Html.button -- Add Ship
            [ Html.Events.onClick address (SetupAddShip shipId)
            ]
            []
        ]
    else Html.div [] []

---- UPDATE ----
type Action
    = SetupOrientationField ShipId
    | SetupRowField ShipId String
    | SetupColumnField ShipId String
    | SetupAddShip ShipId
    | PlayShoot

update : Action -> Model -> Model
update action model =
    case action of
        SetupOrientationField shipId ->
            let
            thePlayer = model.player
            updateShip maybeShip = maybeShip
                |> Maybe.map
                (\ theShip -> { theShip | orientation <- toggleOrientation theShip.orientation } )
            in
            { model | player <- { thePlayer | ships <- (Dict.update shipId updateShip thePlayer.ships) } }
        -- TODO May be able to use the `.row` and `.column` to simplify this.
        -- Maybe could even set the orientation if the action could be tagged with an Orientation.
        -- OR could just change orientation to a boolean and type alias things. Not exactly sure if this would work.
        -- Example:
        -- type alias Horizontal = True
        -- type alias Vertical = False
        SetupRowField shipId rowAsString ->
            let
            thePlayer = model.player
            updateShip maybeShip = maybeShip
                |> Maybe.map
                (\ theShip -> { theShip | row <- toIntOrDefaultOrZero rowAsString theShip.row } )
            in
            { model | player <- { thePlayer | ships <- (Dict.update shipId updateShip thePlayer.ships) } }
        SetupColumnField shipId columnAsString ->
            let
            thePlayer = model.player
            updateShip maybeShip = maybeShip
                |> Maybe.map
                (\ theShip -> { theShip | column <- toIntOrDefaultOrZero columnAsString theShip.column } )
            in
            { model | player <- { thePlayer | ships <- (Dict.update shipId updateShip thePlayer.ships) } }
        SetupAddShip shipId ->
            { model | player <- addShip shipId model.player}

toggleOrientation : Orientation -> Orientation
toggleOrientation orientation =
    if orientation == Vertical then Horizontal else Vertical

toIntOrDefaultOrZero : String -> Int -> Int
toIntOrDefaultOrZero stringToConvert default =
    if stringToConvert == "" then 0 else
    case String.toInt stringToConvert of
        Ok n -> n
        _ -> default

addShip : ShipId -> Player -> Player
addShip shipId thePlayer =
    let
    updateShip maybeShip = maybeShip
        |> Maybe.map
        (\ theShip -> { theShip | added <- (canAddShip theShip thePlayer.primaryGrid thePlayer.ships) } )
    in
    { thePlayer | ships <- (Dict.update shipId updateShip thePlayer.ships) }

canAddShip : Ship -> Grid -> Dict.Dict Int Ship -> Bool
canAddShip ship grid ships =
    -- order here is important for optimization. `shipInBounds` is cheap
    if | not (shipInBounds ship grid) -> False
       | shipOverlaps ship grid ships -> False
       | otherwise -> True

shipOverlaps : Ship -> Grid -> Dict.Dict Int Ship -> Bool
shipOverlaps ship grid ships =
    let shipCoordinates = getShipCoordinates ship in
    ships
        |> Dict.filter (\key v -> v.added)
        |> Dict.values
        |> List.map getShipCoordinates
        |> List.concat
        |> List.foldr (\coord acc -> (List.member coord shipCoordinates) || acc) False

shipInBounds : Ship -> Grid -> Bool
shipInBounds ship grid =
    let
    gridH = Matrix.height grid
    gridW = Matrix.width grid
    isInBounds (shipRow, shipColumn) =
        shipRow >= 0 && shipRow < gridH && shipColumn >= 0 && shipColumn < gridW
    in
    ship
        |> getShipCoordinates
        |> List.map isInBounds
        |> List.all identity

module Battleship where

-- Core
import String
-- Evan
import Html
import Html.Attributes
import Html.Events
import StartApp.Simple as StartApp
-- 3rd Party
import Matrix
-- Battleship
import Fleet
import Grid
import Location
import Player
import Ship

---- MAIN ----
main =
  StartApp.start { model = defaultModel, view = view, update = update }

---- MODEL ----
defaultModel : Model
defaultModel =
  { state = Setup
  , player = Player.defaultPlayer
  , computer = Player.defaultComputer
  }
-- Model
type alias Model =
  { state : State
  , player : Player.Player
  , computer : Player.Player
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


setupControlsView : Signal.Address Action -> Player.Player -> Html.Html
setupControlsView address player =
  let
  html = player.fleet
    |> Fleet.toList
    |> List.map (\ship -> shipFieldView address ship)
  in
  Html.div [] (html ++ [Html.text (toString player.fleet)])

-- Depending on the Action render the proper html input.
shipFieldView : Signal.Address Action -> Ship.Ship -> Html.Html
shipFieldView address ship =
  if not ship.added then
    Html.div []
    [ Html.input -- Ship Row Input
      [ Html.Attributes.value (toString (Location.row ship.location))
      , Html.Events.on "input" Html.Events.targetValue (Signal.message address << SetupRowField ship.id)
      ]
      []
    , Html.input -- Ship Column Input
      [ Html.Attributes.value (toString (Location.column ship.location))
      , Html.Events.on "input" Html.Events.targetValue (Signal.message address << SetupColumnField ship.id)
      ]
      []
    , Html.input -- Ship Orientation
      [ Html.Attributes.type' "radio"
      , Html.Attributes.checked (ship.orientation == Ship.Horizontal)
      , Html.Events.onClick address (SetupOrientationField ship.id)
      ]
      []
    , Html.button -- Add Ship
      [ Html.Events.onClick address (SetupAddShip ship.id)
      ]
      []
    ]
  else Html.div [] []

---- UPDATE ----
type Action
  = SetupOrientationField Int
  | SetupRowField Int String
  | SetupColumnField Int String
  | SetupAddShip Int
  | PlayShoot

update : Action -> Model -> Model
update action model =
  case action of
    SetupOrientationField shipId ->
      let
      player = model.player

      updateShip ship =
        if ship.id == shipId then
          { ship | orientation <- toggleOrientation ship.orientation }
        else
          ship
      in
      { model | player <- { player | fleet <- (Fleet.map updateShip player.fleet) } }
    SetupRowField shipId rowAsString ->
      let
      player = model.player

      updateShip ship =
        if ship.id == shipId then
          Ship.setRow (toIntOrDefaultOrZero rowAsString (Ship.getRow ship)) ship
        else
          ship
      in
      { model | player <- { player | fleet <- (Fleet.map updateShip player.fleet) } }
    SetupColumnField shipId columnAsString ->
      let
      player = model.player

      updateShip ship =
        if ship.id == shipId then
          Ship.setColumn (toIntOrDefaultOrZero columnAsString (Ship.getColumn ship)) ship
        else
          ship
      in
      { model | player <- { player | fleet <- (Fleet.map updateShip player.fleet) } }
    SetupAddShip shipId ->
      { model | player <- Player.addShip shipId model.player}

toggleOrientation : Ship.Orientation -> Ship.Orientation
toggleOrientation orientation =
  if orientation == Ship.Vertical then Ship.Horizontal else Ship.Vertical

toIntOrDefaultOrZero : String -> Int -> Int
toIntOrDefaultOrZero stringToConvert default =
  if stringToConvert == "" then 0 else
  case String.toInt stringToConvert of
    Ok n -> n
    _ -> default

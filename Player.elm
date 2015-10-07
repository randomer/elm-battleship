module Player where

-- The player manages the syn b/w the ships in a fleet and the grid.
-- There is an implicit invariant b/w a ship a fleet and a grid which is that if
-- a ship is `added` then it means that its information has been added to the
-- grid.

-- Core
-- Evan
import Html
-- 3rd Party
import Matrix
-- Battleship
import Fleet
import Grid
import Ship

-- Player
type alias Player =
    { fleet : Fleet.Fleet
    , primaryGrid : Grid.Grid
    , trackingGrid : Grid.Grid
    }
defaultPlayer : Player
defaultPlayer =
    { fleet = Fleet.defaultFleet
    , primaryGrid = Grid.defaultPrimaryGrid
    , trackingGrid = Grid.defaultTrackingGrid
    }
-- TODO Setup a random board for the computer.
-- This will be different than the defaultPlayer function.
defaultComputer : Player
defaultComputer =
    { fleet = Fleet.defaultFleet
    , primaryGrid = Grid.defaultPrimaryGrid
    , trackingGrid = Grid.defaultTrackingGrid
    }

addShip : Int -> Player -> Player
addShip shipId player =
  case Fleet.getShip shipId player.fleet of
    Just ship ->
      if canAddShip ship player then
        { player |
            fleet <- Fleet.updateShip shipId Ship.setAddedTrue player.fleet,
            primaryGrid <- Grid.addShip ship player.primaryGrid
        }
      else
        player
    _ -> player

allShipsAdded : Player -> Bool
allShipsAdded player =
  player
    |> getShips
    |> List.map .added
    |> List.all identity

updateShip : Int -> (Ship.Ship -> Ship.Ship) -> Player -> Player
updateShip shipId fn player =
  { player | fleet <- Fleet.updateShip shipId fn player.fleet }

getShips : Player -> List Ship.Ship
getShips player =
  player.fleet
    |> Fleet.toList

canAddShip : Ship.Ship -> Player -> Bool
canAddShip ship player =
  -- order here is important for optimization. `shipInBounds` is cheap
  if | not (shipInBounds ship player.primaryGrid) -> False
     | shipOverlaps ship player.fleet -> False
     | otherwise -> True

-- private helper for canAddShip
shipOverlaps : Ship.Ship -> Fleet.Fleet -> Bool
shipOverlaps ship fleet =
  let
  shipCoordinates = Ship.getShipCoordinates ship
  in
  fleet
    |> Fleet.toList
    |> List.filter .added
    |> List.map Ship.getShipCoordinates
    |> List.concat
    |> List.foldr (\coord acc -> (List.member coord shipCoordinates) || acc) False

-- private helper for canAddShip
shipInBounds : Ship.Ship -> Grid.Grid -> Bool
shipInBounds ship grid =
  let
  gridH = Grid.getHeight grid
  gridW = Grid.getWidth grid
  isInBounds (shipRow, shipColumn) =
    shipRow >= 0 && shipRow < gridH && shipColumn >= 0 && shipColumn < gridW
  in
  ship
    |> Ship.getShipCoordinates
    |> List.map isInBounds
    |> List.all identity

toHtml : Player -> Html.Html
toHtml player =
  Html.div [] [Grid.toHtml player.primaryGrid, Grid.toHtml player.trackingGrid]

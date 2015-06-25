module Controller.Common where

import Api.Fs (children)
import Control.Monad.Aff (attempt)
import Control.Monad.Aff.Class (liftAff)
import Control.Plus (empty)
import Data.Array (filter, mapMaybe)
import Data.Either (Either(..), either)
import Data.Foldable (fold)
import Data.Maybe (Maybe(..))
import Halogen.HTML.Events.Monad (Event(), andThen)
import Model.Resource
import Model.Path (DirPath())
import Network.HTTP.Affjax (AJAX())

getChildren :: forall i e. (Resource -> Boolean) -> ([Resource] -> Event (ajax :: AJAX | e) i) -> DirPath -> Event (ajax :: AJAX | e) i
getChildren pred f r = do
  ei <- liftAff $ attempt $ children r
  case ei of
    Right items -> do
      let items' = filter pred items
          parents = mapMaybe (either (const Nothing) Just <<< getPath) items
      f items' `andThen` \_ -> fold (getChildren pred f <$> parents)
    _ -> empty

getDirectories :: forall i e. ([Resource] -> Event (ajax :: AJAX | e) i) -> DirPath -> Event (ajax :: AJAX | e) i
getDirectories = getChildren (\x -> isDirectory x || isDatabase x)

getFiles :: forall i e. ([Resource] -> Event (ajax :: AJAX | e) i) -> DirPath -> Event (ajax :: AJAX | e) i
getFiles = getChildren isFile

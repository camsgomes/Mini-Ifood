{-# LANGUAGE NoRebindableSyntax #-}
{-# OPTIONS_GHC -fno-warn-missing-import-lists #-}
{-# OPTIONS_GHC -w #-}
module PackageInfo_minifood (
    name,
    version,
    synopsis,
    copyright,
    homepage,
  ) where

import Data.Version (Version(..))
import Prelude

name :: String
name = "minifood"
version :: Version
version = Version [0,1,0,0] []

synopsis :: String
synopsis = "Mini sistema de delivery pelo terminal"
copyright :: String
copyright = ""
homepage :: String
homepage = ""

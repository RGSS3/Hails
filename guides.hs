import Control.Monad
import Data.Maybe
import qualified Data.Map as M
import System.Process
import Data.List
import System.Directory

editor' = "cmd /c start notepad++"

{- http://guides.rubyonrails.org/ -}
data Arg = Arg Int

data GuideAction = 
    Run     String                       | 
    RunWith String                       |
    Edit    String                       |
    Chdir   String GuideAction           |
    Nop
    deriving(Show)

data GemAction = 
    Install String
    deriving(Show)

data GuideInitCommands = 
   Ruby            |
   Sqlite3         |
   Gem (GemAction) |
   Rails           |
   Bundle          |
   Devise
   deriving(Show)
data ViewMap = 
   ERB        |
   HTML       |
   Raw String |
   ViewMapLast
   deriving (Show, Ord, Eq)

data GuideArgs = 
--new
   New            String                |
   Controller     String                |
   Scaffold       String String         |
   View           ViewMap String String |
   Model          String String         |
--edit
   Gemfile                              |
   Route                                |
   
--server
   Server                               |
   ServerWith String                    |
--database
   Migrate                              |
--last
   GuideArgsLast
   deriving (Show, Ord, Eq)


inst Ruby              = Run "ruby -v"
inst Sqlite3           = Run "sqlite3 --version"
inst (Gem (Install a)) = Run $ "gem install" ++ a
inst Rails             = Run "rails --version"
inst Bundle            = Run "bundle install"
inst Devise            = Run "rails g devise:install"



create (New a)                 = Run $ "rails new " ++ a
create (View _ c a)            = Run $ "rails generate controller " ++ c ++ " " ++ a
create (Controller c)          = Run $ "rails generate controller " ++ c
create (Model m opt)           = Run $ "rails generate model " ++ m ++ " " ++ opt
create (Scaffold s opt)        = Run $ "rails generate scaffold " ++ s ++ " " ++ opt
run    (Server)                = Run "rails server"
run    (ServerWith str)        = Run $ "rails server " ++ str
run    Migrate                 = Run $ "rake db:migrate"
edit   Gemfile                 = Edit "gemfile"
edit   Route                   = Edit "config/routes.rb"
edit   (View ERB  c a)         = Edit $ "app/views/" ++ c ++ "/" ++ a ++ ".html.erb"
edit   (View HTML c a)         = Edit $ "app/views/" ++ c ++ "/" ++ a ++ ".html"
edit   (Controller c)          = Edit $ "app/controllers/" ++ c ++ "_controller.rb"
edit   (Model m _)             = Edit $ "app/models/" ++ m ++ ".rb"
tell   Route                   = Run "rake routes"

execAction q = 
   case q of
     Nop                  -> return ()
     RunWith str          -> do
       runCommand $ str
       return ()
     Edit  str            -> do
       runCommand $ "cmd /c start notepad++ " ++ str
       return ()
     Run str              -> do
       runCommand str
       return ()
     Chdir dir inner  -> do
       backup <- getCurrentDirectory
       setCurrentDirectory dir
       execAction inner
       setCurrentDirectory backup
       return ()

guide = execAction
guideAt app = execAction . (Chdir app)
g' = guideAt "app"

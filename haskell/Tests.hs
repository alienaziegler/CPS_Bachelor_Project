module Tests where

import InterpreterNonCPS as NonCPS
import InterpreterCPS as CPS
import InterpreterMonadic as Monadic

import qualified Data.Map as Map
import Data.Maybe
import Control.Monad.Cont

main :: IO ()
main = testMonadicCPS


testNonCPS :: IO ()
testNonCPS = do

    -- let eval = NonCPS.eval 
    --     Const = NonCPS.Const -- won't work TODO

    
    putStrLn "\n-------- Constant evaluation: ----------------------------"
    putStr $ "5 = " ++ show (NonCPS.eval (NonCPS.Const 5) [])
    
    putStrLn "\n-------- Variable evaluation: ----------------------------"
    putStrLn "Let [(x = 3), (y = 7)]"
    putStr $ "x = " ++ show (NonCPS.eval (NonCPS.Var "x") [("x", NonCPS.NumVal 3), ("y", NonCPS.NumVal 7)])
    
    putStrLn "\n-------- Addition evaluation: ----------------------------"
    putStrLn "Let [(x = 3), (y = 5)]"
    putStr "3 + y = "
    print $ NonCPS.eval (NonCPS.Add (NonCPS.Const 3) (NonCPS.Var "y")) [("x", NonCPS.NumVal 3), ("y", NonCPS.NumVal 5)]
    putStr "x + 5 = "
    print $ NonCPS.eval (NonCPS.Add (NonCPS.Var "x") (NonCPS.Const 5)) [("x", NonCPS.NumVal 3), ("y", NonCPS.NumVal 5)]
    putStr "x + y = "
    print $ NonCPS.eval (NonCPS.Add (NonCPS.Var "x") (NonCPS.Var "y")) [("x", NonCPS.NumVal 3), ("y", NonCPS.NumVal 5)]
    
    putStrLn "\n-------- Function evaluation: ----------------------------"
    let f = NonCPS.Fun ["x", "y"] (NonCPS.Add (NonCPS.Var "x") (NonCPS.Var "y")) 
    putStr $ "f(x,y) = " ++ show (NonCPS.eval f [])

    putStrLn "now let [(x = 7)]"
    putStr $ "f(x,y) = " ++ show (NonCPS.eval f [("x", NonCPS.NumVal 7)])
    
    putStrLn "\n-------- Function application evaluation: ----------------"
    putStr "f(x=1,y=2) = "
    print $ NonCPS.eval (NonCPS.App f [NonCPS.Const 1, NonCPS.Const 2]) []

    putStrLn "now let [(x = 7)]"
    putStr "f(x=1,y=2) = "
    print $ NonCPS.eval (NonCPS.App f [NonCPS.Const 1, NonCPS.Const 2]) [("x", NonCPS.NumVal 7)]

    putStrLn "\n-------- Object evaluation: ------------------------------"
    let obj1 = NonCPS.Obj [("field1", NonCPS.Const 42), ("field2", NonCPS.Const 99)]
    putStr "obj1 = "
    print $ NonCPS.eval obj1 []

    putStrLn " now let [(x = 5)]"
    let obj2 = NonCPS.Obj [("field1", NonCPS.Var "x"), ("field2", f)]
    putStr "obj2 = "
    print $ NonCPS.eval obj2 [("x", NonCPS.NumVal 5)]

    putStrLn "\n-------- Object field evaluation: ------------------------"
    putStrLn "let [(obj1 = ...), (obj2 = ...)]"
    let env = [("obj1", NonCPS.eval obj1 []), ("obj2", NonCPS.eval obj2 [("x", NonCPS.NumVal 5)])]
    let field11 = NonCPS.Field (NonCPS.Var "obj1") "field1"
    let field12 = NonCPS.Field (NonCPS.Var "obj1") "field2"
    let field21 = NonCPS.Field (NonCPS.Var "obj2") "field1"
    let field22 = NonCPS.Field (NonCPS.Var "obj2") "field2"
    putStrLn $ "object1 field1: " ++ show (NonCPS.eval field11 env)
    putStrLn $ "object1 field2: " ++ show (NonCPS.eval field12 env)
    putStrLn $ "object2 field1: " ++ show (NonCPS.eval field21 env)
    putStrLn $ "object2 field2: " ++ show (NonCPS.eval field22 env)

testCPS :: IO ()
testCPS = do
    putStrLn "\n-------- Constant evaluation: ----------------------------"
    putStr $ "5 = " ++ show (CPS.eval (CPS.Const 5) [] id)
    
    putStrLn "\n-------- Variable evaluation: ----------------------------"
    putStrLn "Let [(x = 3), (y = 7)]"
    putStr $ "x = " ++ show (CPS.eval (CPS.Var "x") [("x", CPS.NumVal 3), ("y", CPS.NumVal 7)] id)
    
    putStrLn "\n-------- Addition evaluation: ----------------------------"
    putStrLn "Let [(x = 3), (y = 5)]"
    putStr "3 + y = "
    print $ CPS.eval (CPS.Add (CPS.Const 3) (CPS.Var "y")) [("x", CPS.NumVal 3), ("y", CPS.NumVal 5)] id
    putStr "x + 5 = "
    print $ CPS.eval (CPS.Add (CPS.Var "x") (CPS.Const 5)) [("x", CPS.NumVal 3), ("y", CPS.NumVal 5)] id
    putStr "x + y = "
    print $ CPS.eval (CPS.Add (CPS.Var "x") (CPS.Var "y")) [("x", CPS.NumVal 3), ("y", CPS.NumVal 5)] id
    
    putStrLn "\n-------- Function evaluation: ----------------------------"
    let f = CPS.Fun ["x", "y"] (CPS.Add (CPS.Var "x") (CPS.Var "y")) 
    putStr $ "f(x,y) = " ++ show (CPS.eval f [] id) 

    putStrLn "now let [(x = 7)]"
    putStr $ "f(x,y) = " ++ show (CPS.eval f [("x", CPS.NumVal 7)] id)
    
    putStrLn "\n-------- Function application evaluation: ----------------"
    putStr "f(x=1,y=2) = "
    print $ CPS.eval (CPS.App f [CPS.Const 1, CPS.Const 2]) [] id

    putStrLn "now let [(x = 7)]"
    putStr "f(x=1,y=2) = "
    print $ CPS.eval (CPS.App f [CPS.Const 1, CPS.Const 2]) [("x", CPS.NumVal 7)] id

    putStrLn "\n-------- Object evaluation: ------------------------------"
    let obj1 = CPS.Obj [("field1", CPS.Const 42), ("field2", CPS.Const 99)]
    putStr "obj1 = "
    print $ CPS.eval obj1 [] id 

    putStrLn " now let [(x = 5)]"
    let obj2 = CPS.Obj [("field1", CPS.Var "x"), ("field2", f)]
    putStr "obj2 = "
    print $ CPS.eval obj2 [("x", CPS.NumVal 5)] id

    putStrLn "\n-------- Object field evaluation: ------------------------"
    putStrLn "let [(obj1 = ...), (obj2 = ...)]"
    let env = [("obj1", CPS.eval obj1 [] id), ("obj2", CPS.eval obj2 [("x", CPS.NumVal 5)] id)]
    let field11 = CPS.Field (CPS.Var "obj1") "field1"
    let field12 = CPS.Field (CPS.Var "obj1") "field2"
    let field21 = CPS.Field (CPS.Var "obj2") "field1"
    let field22 = CPS.Field (CPS.Var "obj2") "field2"
    putStrLn $ "object1 field1: " ++ show (CPS.eval field11 env id)
    putStrLn $ "object1 field2: " ++ show (CPS.eval field12 env id)
    putStrLn $ "object2 field1: " ++ show (CPS.eval field21 env id)
    putStrLn $ "object2 field2: " ++ show (CPS.eval field22 env id)


-- testMonadicCPS :: IO ()
-- testMonadicCPS = do
--     putStrLn "\n-------- Constant evaluation: ----------------------------"
--     putStr $ "5 = " ++ show (runCont $ Monadic.eval (Monadic.Const 5) [])
    
--     putStrLn "\n-------- Variable evaluation: ----------------------------"
--     putStrLn "Let [(x = 3), (y = 7)]"
--     putStr $ "x = " ++ show (Monadic.eval (Monadic.Var "x") [("x", Monadic.NumVal 3), ("y", Monadic.NumVal 7)])
    
--     putStrLn "\n-------- Addition evaluation: ----------------------------"
--     putStrLn "Let [(x = 3), (y = 5)]"
--     putStr "3 + y = "
--     print $ Monadic.eval (Monadic.Add (Monadic.Const 3) (Monadic.Var "y")) [("x", Monadic.NumVal 3), ("y", Monadic.NumVal 5)]
--     putStr "x + 5 = "
--     print $ Monadic.eval (Monadic.Add (Monadic.Var "x") (Monadic.Const 5)) [("x", Monadic.NumVal 3), ("y", Monadic.NumVal 5)]
--     putStr "x + y = "
--     print $ Monadic.eval (Monadic.Add (Monadic.Var "x") (Monadic.Var "y")) [("x", Monadic.NumVal 3), ("y", Monadic.NumVal 5)]
    
--     putStrLn "\n-------- Function evaluation: ----------------------------"
--     let f = Monadic.Fun ["x", "y"] (Monadic.Add (Monadic.Var "x") (Monadic.Var "y")) 
--     putStr $ "f(x,y) = " ++ show (Monadic.eval f [])

--     putStrLn "now let [(x = 7)]"
--     putStr $ "f(x,y) = " ++ show (Monadic.eval f [("x", Monadic.NumVal 7)])
    
--     putStrLn "\n-------- Function application evaluation: ----------------"
--     putStr "f(x=1,y=2) = "
--     print $ Monadic.eval (Monadic.App f [Monadic.Const 1, Monadic.Const 2]) []

--     putStrLn "now let [(x = 7)]"
--     putStr "f(x=1,y=2) = "
--     print $ Monadic.eval (Monadic.App f [Monadic.Const 1, Monadic.Const 2]) [("x", Monadic.NumVal 7)]


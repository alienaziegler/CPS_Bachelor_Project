module InterpreterCPS where
import Data.Maybe ( fromMaybe )
import qualified Data.Map as Map

-- CPS Interpreter, explicit Cont

type Ident = String

type Address = Int

data Expr = Const Int
          | Var Ident
          | Add Expr Expr
          | Fun [Ident] Expr
          | App Expr [Expr]
          | Obj [(Ident, Expr)]
          | Field Expr Ident
  deriving (Show, Eq)

data Value = NumVal Int
           | FunVal [Ident] Expr Env
           | PtrVal Address
  deriving (Show, Eq)

type ObjValue = [(Ident, Value)]

type Env = [(Ident, Value)] -- [(Ident, Result)] ?

data State = State { free :: Address, store :: Map.Map Address ObjValue }
  deriving (Show, Eq)

type Result = (Value, State)

type Cont a = a -> State -> Result

eval :: Expr -> Env -> State -> Cont Value -> Result
eval (Const c) env s k = k (NumVal c) s
eval (Var v) env s k = k (fromMaybe (error "Variable not found in environment")  (lookup v env)) s
eval (Add expr1 expr2) env s k = eval expr1 env s (\(NumVal left) s -> eval expr2 env s (\(NumVal right) s -> k (NumVal (left+right)) s))
eval (Fun params expr) env s k = k (FunVal params expr env) s
eval (App fun args) env s k = eval fun env s (\(FunVal params expr env') s -> -- will this work for k /= sid ? 
                            evalMultiple args env s (\argVals s ->
                            eval expr (zip params argVals ++ env') s k))
eval (Obj obj) env s k = evalMultiple (map snd obj) env s (\fieldVals s ->
                            let newaddr = free s + 1 in
                            let s' = State {free = newaddr, store = Map.insert (free s) (zip (map fst obj) fieldVals) (store s)} in
                            k (PtrVal (free s)) s')
eval (Field obj field) env s k =  case eval obj env s k of
  (PtrVal ptr, State free store) -> k (fromMaybe (error "Field not found") (lookup field (store Map.! ptr))) (State free store)
  _ -> k (error "Non-object value") s

evalMultiple :: [Expr] -> Env -> State -> Cont [Value] -> Result
evalMultiple [] env s k = k [] s 
evalMultiple (arg : args) env s k = eval arg env s (\argVal s -> evalMultiple args env s (\restVals s -> k (argVal : restVals) s))

-- SetField :: Expr -> Field -> Expr
-- SetField Expr Field Expr
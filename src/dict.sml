
structure TreeDict : DICT =
struct

  fun log2 (n : int) : int = 
      case n of 
          0 => 0 (* hack *)
        | 1 => 1
        | _ => 1 + log2 (n div 2)

  datatype ('k, 'v) tree =
      Empty
    | Node of ('k, 'v) tree * ('k * 'v) * ('k, 'v) tree

  type ('k,'v) dict = ('k, 'v) tree 

  val empty = Empty

  fun size t =
        case t of
            Empty => 0
          | Node(l,_,r) => 1 + size l + size r
      
  fun insert (cmp, d, (k, v)) =
    case d of
      Empty => Node (empty, (k,v), empty)
    | Node (L, (k', v'), R) =>
      case cmp (k,k') of
        EQUAL => Node (L, (k, v), R)
      | LESS => Node (insert (cmp, L, (k, v)), (k', v'), R)
      | GREATER => Node (L, (k', v'), insert (cmp, R, (k, v)))

  fun lookup (cmp, d, k) =
    case d of
      Empty => NONE
    | Node (L, (k', v'), R) =>
      case cmp (k,k') of
        EQUAL => SOME v'
      | LESS => lookup (cmp, L, k)
      | GREATER => lookup (cmp, R, k)

  fun toString (kvts, d) =
      case d of
          Empty => ""
        | Node(l,kv,r) => toString (kvts, l) ^ " " ^ kvts kv ^ " " ^ toString (kvts, r)

  fun lookup' (cmp : 'k * 'k -> order, d, k) = case (lookup (cmp, d, k)) of NONE => raise Fail "key not found in dictionary" | SOME v => v
      

  (* Purpose: Splits the tree at a given key into three parts: less than, equal to, and greater than the key. *)
    
  fun splitAt (cmp, t, k) =
    let
        fun split Empty = (Empty, NONE, Empty)
          | split (Node (l, (k', v'), r)) =
            case cmp(k, k') of
                EQUAL => (l, SOME v', r)
              | LESS =>
                let val (ll, found, lr) = split l
                in (ll, found, Node(lr, (k', v'), r)) end
              | GREATER =>
                let val (rl, found, rr) = split r
                in (Node(l, (k', v'), rl), found, rr) end
    in
        split t
    end

  (* Purpose: Merges two dictionaries. If a key appears in both dictionaries, 
           a provided function is used to combine their values. *)
           
  fun merge' (cmp, combine, d1, d2) =
    let
        fun mergeTrees Empty d = d
          | mergeTrees d Empty = d
          | mergeTrees (Node (l1, (k, v1), r1)) d2 =
            let
                val (left, maybe_v2, right) = splitAt (cmp, d2, k)
                val new_v = case maybe_v2 of
                              NONE => v1
                            | SOME v2 => combine(v1, v2)
                val new_left = mergeTrees l1 left
                val new_right = mergeTrees r1 right
            in
                Node (new_left, (k, new_v), new_right)
            end
    in
        mergeTrees d1 d2
    end

  (* optimize inserts: if merging with a 1-element dictionary, insert instead, because it only needs to walk down one path of the tree *)
  fun insertWith (cmp : 'k * 'k -> order, c : 'v * 'v -> 'v, d : ('k,'v) dict, (k : 'k, v : 'v)) : ('k,'v) dict =
    case d of
      Empty => Node (empty, (k,v), empty)
    | Node (L, (k', v'), R) =>
      case cmp (k,k') of
          EQUAL => Node (L, (k, (c(v,v'))), R)
        | LESS => Node (insertWith (cmp, c, L, (k, v)), (k', v'), R)
        | GREATER => Node (L, (k', v'), insertWith (cmp, c, R, (k, v)))

  fun merge (cmp : 'k * 'k -> order, c : 'v * 'v -> 'v, d1 : ('k,'v) dict , d2 : ('k,'v) dict) : ('k,'v) dict = 
      case d1 of
          Node(Empty, kv1, Empty) => insertWith (cmp, c, d2, kv1)
        | _ => case d2 of
                 Node(Empty, kv2, Empty) => insertWith (cmp, c, d1, kv2)
               | _ => merge' (cmp, c, d1,d2)

  (* Purpose: Converts the dictionary to a sequence of key-value pairs, ordered by keys. *)
  fun toSeq tree =
    case tree of
        Empty => Seq.empty()
      | Node (l, kv, r) =>
            let
                val leftSeq = toSeq l
                val rightSeq = toSeq r
            in
                Seq.append (leftSeq, Seq.cons(kv, rightSeq))
            end

  fun map (f, d) = 
      case d of
          Empty => Empty
        | Node(l,(k,v),r) => Node (map (f, l) , (k, f v) , map (f, r))

end

structure Dict :> DICT = TreeDict




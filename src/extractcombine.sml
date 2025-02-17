
structure ExtractCombine :> EXTRACT_COMBINE =
struct

    fun extractcombine (compare_fn, extractor_fn, combiner_fn, dataset) =
        let
            fun combinePair (dict, (key, value)) =
                case Dict.lookup (compare_fn, dict, key) of
                    NONE => Dict.insert (compare_fn, dict, (key, value))
                  | SOME existing_value => Dict.insert (compare_fn, dict, (key, combiner_fn (existing_value, value)))

            fun combineSeq (kv_seq) =
                let
                    fun loop (dict, i) =
                        if i = Seq.length kv_seq then dict
                        else
                            let
                                val (key, value) = Seq.nth (i, kv_seq)
                                val updated_dict = combinePair (dict, (key, value))
                            in
                                loop (updated_dict, i + 1)
                            end
                in
                    loop (Dict.empty, 0)
                end

            val combined_result = MR.mapreduce (
                                    (fn doc => combineSeq (extractor_fn doc)),          
                                    Dict.empty,                                         
                                    (fn (dict1, dict2) => Dict.merge (compare_fn, combiner_fn, dict1, dict2)),  
                                    dataset)
        in
            combined_result
        end
end

    



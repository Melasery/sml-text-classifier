
structure NaiveBayes :> NAIVE_BAYES_CLASSIFIER =
struct

    type category = string

    type labeled_document = category * string Seq.seq
    type document = string Seq.seq
        
    type statistics = 
          (category,int) Dict.dict           (* maps each category to number of documents with that category *)
        * (category,int) Dict.dict           (* maps each category to number of words in documents with that category *)
        * (category * string, int) Dict.dict (* maps each (cat,word) to frequency *)
        * category Seq.seq                   (* list of categories (no duplicates) *)
        * int                                (* total number of documents *)
        * int                                (* total number of different words *)


    fun gather (train : labeled_document MR.mapreducable) : statistics =     let
        fun dictKeys dict =
            let
                fun extractKeys seq acc =
                    if Seq.length seq = 0 then
                        acc
                    else
                        let
                            val (firstSeq, rest) = Seq.split(1, seq)
                            val (k, _) = Seq.nth(0, firstSeq)
                        in
                            extractKeys rest (Seq.cons(k, acc))
                        end
                val keySeq = extractKeys (Dict.toSeq dict) (Seq.empty())
            in
                keySeq
            end

        (*  the number of documents in the category *)
        val countDocsPerCategory =
            ExtractCombine.extractcombine (
                String.compare,
                (fn (category, _) => Seq.singleton (category, 1)),
                (fn (x, y) => x + y),
                train)

        (* the total number of words in the category (counting duplicates) *)
        val countWordsPerCategory =
            ExtractCombine.extractcombine (
                String.compare,
                (fn (category, doc) => Seq.singleton (category, Seq.length doc)),
                (fn (x, y) => x + y),
                train)

        (* the number of times the word occurs in documents with the category *)
        val countWordOccurrences =
            ExtractCombine.extractcombine (
                (fn ((cat1, word1), (cat2, word2)) =>
                    case String.compare(cat1, cat2) of
                        EQUAL => String.compare(word1, word2)
                      | order => order),
                (fn (category, doc) => 
                    let
                        fun createSeq i acc =
                            if i >= Seq.length doc then
                                acc
                            else
                                let
                                    val word = Seq.nth(i, doc)
                                    val pair = (category, word)
                                    val newAcc = Seq.cons((pair, 1), acc)
                                in
                                    createSeq (i + 1) newAcc
                                end
                    in
                        createSeq 0 (Seq.empty())
                    end),
                (fn (x, y) => x + y),
                train)

        (* the sequence of all categories *)
        val collectCategories =
            ExtractCombine.extractcombine (
                String.compare,
                (fn (category, _) => Seq.singleton (category, category)),
                (fn (_, c) => c),
                train)

        (* the total number of classified documents *)
        val totalDocs =
            MR.mapreduce (fn _ => 1, 0, (fn (x, y) => x + y), train)

        (* the total number of distinct words used in all documents ( not counting duplicates). *)
        fun distinctWordsHelp seq acc =
            if Seq.length seq = 0 then
                acc
            else
                let
                    val (firstSeq, rest) = Seq.split(1, seq)
                    val (_, word) = Seq.nth(0, firstSeq)
                    val newAcc = if Dict.lookup (String.compare, acc, word) = NONE 
                                 then Dict.insert (String.compare, acc, (word, ())) 
                                 else acc
                in
                    distinctWordsHelp (rest) (newAcc)
                end

        fun extractKeysFromDict seq acc =
            if Seq.length seq = 0 then
                acc
            else
                let
                    val (firstSeq, rest) = Seq.split(1, seq)
                    val ((cat, word), _) = Seq.nth(0, firstSeq)
                    val newAcc = Seq.cons((cat, word), acc)
                in
                    extractKeysFromDict rest newAcc
                end

        val wordPairsSeq = extractKeysFromDict (Dict.toSeq countWordOccurrences) (Seq.empty())

        val distinctWordsDict = distinctWordsHelp wordPairsSeq Dict.empty
        val distinctWords = Dict.size distinctWordsDict

        val categoriesSeq = dictKeys collectCategories
    in
        (countDocsPerCategory, countWordsPerCategory, countWordOccurrences, categoriesSeq, totalDocs, distinctWords)
    end



    fun possible_classifications 
        ((num_docs_by_cat,
          num_words_by_cat,
          freqs,
          all_categories, 
          total_num_docs,
          total_num_words) : statistics,
         test_doc : document) : (category * real) Seq.seq =

    let
        fun log_prob_for_category category =
            let
                val num_docs_in_cat = Dict.lookup(String.compare, num_docs_by_cat, category)
                val prior_prob = case num_docs_in_cat of
                                    NONE => 0.0
                                  | SOME count => Real.fromInt(count) / Real.fromInt(total_num_docs)
                
                val log_prior = Math.ln(prior_prob)

                fun compute_likelihoods seq acc =
                    if Seq.length seq = 0 then
                        acc
                    else
                        let
                            val (firstSeq, rest) = Seq.split(1, seq)
                            val word = Seq.nth(0, firstSeq)
                            val word_in_cat_count = Dict.lookup((fn ((c1, w1), (c2, w2)) =>
                                                                    case String.compare(c1, c2) of
                                                                        EQUAL => String.compare(w1, w2)
                                                                      | order => order),
                                                                freqs, (category, word))
                            val total_words_in_cat = Dict.lookup(String.compare, num_words_by_cat, category)
                            val log_likelihood = case (word_in_cat_count, total_words_in_cat) of
                                                   (SOME word_count, SOME total_count) => 
                                                       Math.ln(Real.fromInt(word_count) / Real.fromInt(total_count))
                                                 | _ => Math.ln(1.0 / Real.fromInt(total_num_words))  
                            val newAcc = acc + log_likelihood
                        in
                            compute_likelihoods rest newAcc
                        end

                val log_likelihood = compute_likelihoods test_doc 0.0
            in
                (category, log_prior + log_likelihood)
            end

        fun compute_all_categories seq acc =
            if Seq.length seq = 0 then
                acc
            else
                let
                    val (firstSeq, rest) = Seq.split(1, seq)
                    val category = Seq.nth(0, firstSeq)
                    val log_prob = log_prob_for_category category
                    val newAcc = Seq.cons(log_prob, acc)
                in
                    compute_all_categories rest newAcc
                end

    in
        compute_all_categories all_categories (Seq.empty())
    end



fun classify (stats : statistics, test_doc : document) : (category * real) =
    let
        val (num_docs_by_cat,
             num_words_by_cat,
             freqs,
             all_categories, 
             total_num_docs,
             total_num_words) = stats

        val classifications = possible_classifications (
                                  (num_docs_by_cat,
                                   num_words_by_cat,
                                   freqs,
                                   all_categories, 
                                   total_num_docs,
                                   total_num_words), 
                                  test_doc)
        
        fun find_max_classification seq (best_cat, best_prob) =
            if Seq.length seq = 0 then (best_cat, best_prob)
            else
                let
                    val (cat, prob) = Seq.nth(0, seq)
                    val rest = Seq.drop(1, seq)
                in
                    if prob > best_prob then 
                        find_max_classification rest (cat, prob)
                    else 
                        find_max_classification rest (best_cat, best_prob)
                end

    in
        if Seq.length classifications = 0 then ("", Real.negInf)
        else find_max_classification classifications ("", Real.negInf)
    end


    fun train_classifier (train : labeled_document MR.mapreducable) : document -> (category * real) =
    let
        val stats = gather train

        fun classify_document (doc : document) : (category * real) = 
            classify (stats, doc)

    in        classify_document
    end

end



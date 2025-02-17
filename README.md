# Text Classification Framework in SML 

## Project Overview
This project provides a **framework for text classification** using:
- **Extract-Combine Processing**: A functional MapReduce-like structure.
- **Naïve Bayes Classifier**: A statistical model for categorizing text.
- **Word Frequency Analysis**: A module to count occurrences of words in documents.

**Key Features:**
- Supports **parallel processing** using extract-combine.
- Implements a **trainable classifier** for document categorization.
- Provides a **modular structure**—users can plug in their **own dataset**.

### **Who is this for?**
Anyone studying **functional programming**  
Researchers working on **text classification**  
Developers needing a **modular SML framework** for document analysis  



## How the Framework Works
### **1️⃣ Extract-Combine Model**
- Implements **MapReduce-style parallelism**.
- Extracts word frequencies and combines them efficiently.
- Useful for **big text processing** (word counting, tokenization).

### **2️⃣ Naïve Bayes Classifier**
- Uses **Bayes' Theorem** to categorize documents.
- Learns from labeled training data, predicts **document categories**.
- Can be extended for **spam detection, sentiment analysis**.

### **3️⃣ Word Frequency Counter**
- Reads documents and **counts word occurrences**.
- Can be used as a **preprocessing step** for classifiers.



## Project Structure

```
/text-classification-framework
│── /src/                    
│    ├── classify.sml           # Naïve Bayes classifier implementation
│    ├── dict.sml               # Dictionary structure for classifier
│    ├── extractcombine.sml     # Extract-Combine framework
│    ├── wordfreq.sml           # Word frequency counter
│    ├── sources-ec.cm          # Compilation Manager file for Extract-Combine
│    ├── sources-classify-seq.cm # Compilation Manager file for Classifier
│── README.md                    # Documentation
│── .gitignore                  
│── LICENSE                    
│── Makefile                   
```


The following files were provided by **Professor Dan Licata** and are included for completeness:
- `sequtils.sig`
- `mapreduce.sig`
- `mapreduce.sml`
- `sequtils.sml`
- `filemr.sml`
- `extractcombine.sig`
- `classify.sig`
- `testclassify.sml`
- `testclassify-seq.sml`

These files serve as a foundation for the classification framework but were not authored by Marouan El-Asery.



## Key Source Files
- **`classify.sml`** → Implements the Naïve Bayes classification model.
- **`dict.sml`** → A dictionary structure to store word frequencies.
- **`extractcombine.sml`** → Defines a functional Extract-Combine (MapReduce) framework.
- **`wordfreq.sml`** → Extracts and counts word frequencies from text data.



## Getting Started

### **1️⃣ Clone the repository**
```bash
git clone https://github.com/Melasery/text-classification-framework.git
cd text-classification-framework
```

### **2️⃣ Compile the SML Modules**
To compile and load the framework:
```sml
CM.make "sources-ec.cm";      (* Extract-Combine Processing *)
CM.make "sources-classify-seq.cm";  (* Naïve Bayes Classifier *)
```

### **3️⃣ Run Word Frequency Analysis**
```sml
- CM.make "sources-ec.cm";
- WordFreq.test();
```



## License
This project is licensed under the **MIT License** – see the [LICENSE](LICENSE) file for details.




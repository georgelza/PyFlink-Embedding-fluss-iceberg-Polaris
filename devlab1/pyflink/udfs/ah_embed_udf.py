#######################################################################################################################
#
#
#   Project             :   Account Holder... Streaming account holder embedding vectorizer 
#   File                :   ah_embed_udf.py
#   Created             :   8 Dec 2025
#
#   Description         :   Calculate vector values for record arriving in source table, outputting the columns + vector 
#                       :   to a new target table
#                       :
#   Misc Reading        :   https://www.kdnuggets.com/2025/05/confluent/a-data-scientists-guide-to-data-streaming
#                       :   https://www.youtube.com/watch?v=Tn4n9xKE1ug
#                       :   https://www.decodable.co/blog/a-hands-on-introduction-to-pyflink
#
#
#
#
########################################################################################################################
__author__      = "George Leonard"
__email__       = "georgelza@gmail.com"
__version__     = "1.0.0"
__copyright__   = "Copyright 2025, - G Leonard"

"""
Standalone Python UDF for generating account holder embeddings
Can be registered in Flink SQL using CREATE TEMPORARY FUNCTION
"""

from pyflink.table.udf import udf
from pyflink.table import DataTypes
from sentence_transformers import SentenceTransformer
import torch
import time, logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Counter for progress tracking
processed_count = 0

# --------------------------------------------------------------------------
# Constants
# --------------------------------------------------------------------------
# https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2
MODEL = 'sentence-transformers/all-MiniLM-L6-v2'

# --------------------------------------------------------------------------
# Define UDF for embedding generation
# --------------------------------------------------------------------------
@udf(result_type=DataTypes.ARRAY(DataTypes.DOUBLE()))
def generate_ah_embedding(target_dimensions
                          ,firstname 
                          ,lastname 
                          ,dob
                          ,gender
                          ,children 
                          ,address 
                          ,accounts
                          ,emailaddress
                          ,mobilephonenumber):
    """
        Generate <target_dimensions> dimensional embeddings for user profiles using sentence-transformers.
        This UDF lazy-loads the model to avoid serialization issues.

        Args:
            embedding dimensions,
            accountHolder details,
            
        Returns:
            array of DOUBLE: ....
    """
    global processed_count
    
    try:
        processed_count += 1
        
        # Log every 100 records
        if processed_count % 100 == 0:
            logger.info(f"Processed Ah {processed_count} records so far...")
        
        # Use a class variable to cache the model across invocations
        if not hasattr(generate_ah_embedding, 'model'):
            generate_ah_embedding.model = SentenceTransformer(MODEL)
            generate_ah_embedding.model.eval()
        
        # Build text representation of the user profile
        transaction_parts = []
        
        if firstname:
            transaction_parts.append(f"First name: {firstname}")
        if lastname:
            transaction_parts.append(f"Last name: {lastname}")
        if dob:
            transaction_parts.append(f"Date of birth: {dob}")
        if gender:
            transaction_parts.append(f"Gender: {gender}")
        if children is not None:
            transaction_parts.append(f"Children: {children}")
        if address:
            transaction_parts.append(f"Address: {address}")
        if accounts:
            transaction_parts.append(f"Accounts: {accounts}")
        if emailaddress:
            transaction_parts.append(f"Email: {emailaddress}")
        if mobilephonenumber:
            transaction_parts.append(f"Mobile: {mobilephonenumber}")
        
        # Combine all parts into a single text
        transaction_text = ". ".join(transaction_parts)
        
        # Handle empty profile
        if not transaction_text.strip():
            transaction_text = "Unknown account holder profile"
        
        # Defining it here so that we exclude the first slow run.
        start_time = time.time()
        
        # Generate embedding
        with torch.no_grad():        
            embedding = generate_ah_embedding.model.encode(
                transaction_text, 
                convert_to_numpy=True,
                show_progress_bar=False
            )
    
        elapsed = time.time() - start_time
        
        if elapsed > 1.0:  # Log slow operations
            logger.warning(f"Slow Ah Embedding generation rt: {elapsed:.2f}s for record {processed_count}")
        
        else:
            logger.info(f"Embedding Ah generation rt: {elapsed:.2f}s for record {processed_count}")

        # Convert to list of floats for Flink        
        final_size = int(target_dimensions)
        return embedding[:final_size].astype('float64').tolist()

    
    except Exception as e:
        logger.error(f"UDF Error: Ah processing record {processed_count}: {str(e)}", exc_info=True)
        # Return empty embedding on error instead of failing
        return [0.0] * target_dimensions

# end generate_ah_embedding
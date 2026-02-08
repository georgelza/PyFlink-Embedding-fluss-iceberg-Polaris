#######################################################################################################################
#
#
#   Project             :   Transactions... Streaming Transactions embedding vectorizer 
#   File                :   txn_embed_udf.py
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
Standalone Python UDF for generating transaction embeddings
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
MODEL      = 'sentence-transformers/all-MiniLM-L6-v2'

# --------------------------------------------------------------------------
# Define UDF for embedding generation
# --------------------------------------------------------------------------
@udf(result_type=DataTypes.ARRAY(DataTypes.DOUBLE()))
def generate_txn_embedding(target_dimensions, transactionid, eventtime, direction, eventtype, creationdate,
                           accountholdernationalid, accountholderaccount,
                           counterpartynationalid, counterpartyaccount,
                           tenantid, fromid, accountagentid, fromfibranchid,
                           accountnumber, toid, accountidcode, counterpartyagentid,
                           tofibranchid, counterpartynumber, counterpartyidcode,
                           amount, msgtype, settlementclearingsystemcode,
                           paymentclearingsystemreference, requestexecutiondate,
                           settlementdate, destinationcountry, localinstrument,
                           msgstatus, paymentmethod, settlementmethod,
                           transactiontype, verificationresult, numberoftransactions,
                           schemaversion, usercode):
    """
        Generate <target_dimensions>-dimensional embeddings for financial transactions using sentence-transformers.
        This UDF lazy-loads the model to avoid serialization issues.

        Args:
            embedding dimensions,
            transaction details,
            
        Returns:
            array of DOUBLE: ....
    """
    global processed_count
    
    try:
        processed_count += 1

        # Log every 100 records
        if processed_count % 100 == 0:
            logger.info(f"Processed Txn {processed_count} records so far...")
                
        # Use a class variable to cache the model across invocations
        if not hasattr(generate_txn_embedding, 'model'):
            generate_txn_embedding.model = SentenceTransformer(MODEL)
            generate_txn_embedding.model.eval()
        
        # Build a structured text representation of the transaction
        transaction_parts = []
        
        if transactionid:
            transaction_parts.append(f"Txn time: {transactionid}")
        if eventtime:
            transaction_parts.append(f"Event time: {eventtime}")
        if direction:
            transaction_parts.append(f"Direction: {direction}")
        if eventtype:
            transaction_parts.append(f"Event type: {eventtype}")
        if creationdate:
            transaction_parts.append(f"Creation date: {creationdate}")
        if accountholdernationalid:
            transaction_parts.append(f"Account holder national ID: {accountholdernationalid}")
        if accountholderaccount:
            transaction_parts.append(f"Account holder account: {accountholderaccount}")
        if counterpartynationalid:
            transaction_parts.append(f"Counterparty national ID: {counterpartynationalid}")
        if counterpartyaccount:
            transaction_parts.append(f"Counterparty account: {counterpartyaccount}")
        if tenantid:
            transaction_parts.append(f"Tenant ID: {tenantid}")
        if fromid:
            transaction_parts.append(f"From ID: {fromid}")
        if accountagentid:
            transaction_parts.append(f"Account agent ID: {accountagentid}")
        if fromfibranchid:
            transaction_parts.append(f"From FI branch ID: {fromfibranchid}")
        if accountnumber:
            transaction_parts.append(f"Account number: {accountnumber}")
        if toid:
            transaction_parts.append(f"To ID: {toid}")
        if accountidcode:
            transaction_parts.append(f"Account ID code: {accountidcode}")
        if counterpartyagentid:
            transaction_parts.append(f"Counterparty agent ID: {counterpartyagentid}")
        if tofibranchid:
            transaction_parts.append(f"To FI branch ID: {tofibranchid}")
        if counterpartynumber:
            transaction_parts.append(f"Counterparty number: {counterpartynumber}")
        if counterpartyidcode:
            transaction_parts.append(f"Counterparty ID code: {counterpartyidcode}")
        if amount:
            transaction_parts.append(f"Amount: {amount}")
        if msgtype:
            transaction_parts.append(f"Message type: {msgtype}")
        if settlementclearingsystemcode:
            transaction_parts.append(f"Settlement clearing system code: {settlementclearingsystemcode}")
        if paymentclearingsystemreference:
            transaction_parts.append(f"Payment clearing system reference: {paymentclearingsystemreference}")
        if requestexecutiondate:
            transaction_parts.append(f"Request execution date: {requestexecutiondate}")
        if settlementdate:
            transaction_parts.append(f"Settlement date: {settlementdate}")
        if destinationcountry:
            transaction_parts.append(f"Destination country: {destinationcountry}")
        if localinstrument:
            transaction_parts.append(f"Local instrument: {localinstrument}")
        if msgstatus:
            transaction_parts.append(f"Message status: {msgstatus}")
        if paymentmethod:
            transaction_parts.append(f"Payment method: {paymentmethod}")
        if settlementmethod:
            transaction_parts.append(f"Settlement method: {settlementmethod}")
        if transactiontype:
            transaction_parts.append(f"Transaction type: {transactiontype}")
        if verificationresult:
            transaction_parts.append(f"Verification result: {verificationresult}")
        if numberoftransactions is not None:
            transaction_parts.append(f"Number of transactions: {numberoftransactions}")
        if schemaversion is not None:
            transaction_parts.append(f"Schema version: {schemaversion}")
        if usercode:
            transaction_parts.append(f"User code: {usercode}")
        
        # Combine all parts into a single text
        transaction_text = ". ".join(transaction_parts)
        
        # Handle empty transaction
        if not transaction_text.strip():
            transaction_text = "Unknown transaction profile"
        
        # Defining it here so that we exclude the first slow run.
        start_time = time.time()        
    
        # Generate embedding
        with torch.no_grad():
            embedding = generate_txn_embedding.model.encode(
                transaction_text, 
                convert_to_numpy=True,
                show_progress_bar=False
            )
    
        elapsed = time.time() - start_time
        
        if elapsed > 1.0:  # Log slow operations
            logger.warning(f"Slow Txn Embedding generation rt: {elapsed:.2f}s for record {processed_count}")
        
        else:
            logger.info(f"Embedding Txn generation rt: {elapsed:.2f}s for record {processed_count}")

        # Convert to list of floats for Flink        
        final_size = int(target_dimensions)
        return embedding[:final_size].astype('float64').tolist()

    
    except Exception as e:
        logger.error(f"UDF Error: Txn processing record {processed_count}: {str(e)}", exc_info=True)
        # Return empty embedding on error instead of failing
        return [0.0] * target_dimensions

# end generate_txn_embedding

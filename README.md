# SObject Work Queue #

> ![SObject Work Queue : How work is definied, enqueued and processed](https://dl.dropboxusercontent.com/u/240888/SObjectWorkQueueInfrastructure.png)
 
## Design Criteria: ##
- Must prevent Max 5 batch in parallel limit - We should never run into this limit with work that is processed over the queue.	 	 	 
- The queue needs to be so generic that "work" on any type of database object needs to be enqueued.	 	 	 
- Any type of modification of database objects need to be possible. This should be transparently handled by the queue.	 	 	 
- Provide error diagnostics like Batch or better. 	 
- Secures data integrity like Batch or better. Failures should not leave data in inconsistent state or user of the infrastructure should be able to handle them.	 	 	 
- Support / Allow for locking: Single processors should decide whether or not a temporary locking of the records is needed and use a central locking mechanism less quirky than the current one.	 	 	 
- Work that can be run synchronously, should not be queued and processed asynch.


## SObject Work Queue License ##

Copyright (c) 2013, Up2Go International, LLC All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.5.0;

import "../../lib/SafeMath.sol";
import "../../lib/AddressUtil.sol";
import "../../tracing/Traceable.sol";
import "../../tracing/TraceManager.sol";
import "../../lib/Strings.sol";

contract TraceableReporter {

    using Strings for *;
    using Strings for address;

    constructor() public {

    }

    function report(address tm, string calldata label, bool brief) external view returns (string memory){
        TraceManager traceManager = TraceManager(tm);
        Traceable traceable = traceManager.getTraceable(label);
        return _report(traceable, brief);
    }

    function report(address tm, uint256 tokenId, bool brief) external view returns (string memory){
        TraceManager traceManager = TraceManager(tm);
        Traceable traceable = traceManager.getTraceable(tokenId);
        return _report(traceable, brief);
    }

    function _report(Traceable traceable, bool brief) internal view returns (string memory){
        Traceable[] memory chain = new Traceable[](traceable.chainLength());
        if ( !brief ){
            Traceable loopItem = traceable;
            for(uint i = 0; i < traceable.chainLength() ; i++ ){
                chain[i] = loopItem;
                loopItem = loopItem.genesis();
            }
            bool append = false;
            string memory ret = "{".toSlice().toString();
            ret = ret.toSlice().concat(traceableToJson(traceable, false, true).toSlice());
            ret = ret.toSlice().concat(",\"chain\":[".toSlice());
            for(uint i = chain.length ; i > 0 ; i-- ){
                if ( append ){
                    ret = ret.toSlice().concat(",".toSlice());
                }
                ret = ret.toSlice().concat(traceableToJson(chain[i - 1], true, false).toSlice());
                append = true;
            }
            ret = ret.toSlice().concat("]".toSlice());
            append = false;
            ret = ret.toSlice().concat(",\"changes\":[".toSlice());
            for(uint i = chain.length ; i > 1 ; i-- ) {
               Traceable nextT = chain[i - 2];
               uint256 nextB = nextT.createBlock();
               uint256 changesLength = chain[i - 1].changesLength();
               for(uint j = 0; j < changesLength ; j++ ){
                    (string memory eventId,
                    string memory eventType,
                    string memory eventHash,
                    string memory eventData,
                    uint256 eventTime,
                    uint256 eventBlock,
                    address changedBy) = chain[i - 1].changesAt(j);
                    if ( eventBlock > nextB )
                      break;
                    if ( append ){
                        ret = ret.toSlice().concat(",".toSlice());
                    }
                    ret = ret.toSlice().concat("{ \"eventId\":\"".toSlice());
                    ret = ret.toSlice().concat(eventId.toSlice());
                    ret = ret.toSlice().concat("\",\"eventType\":\"".toSlice());
                    ret = ret.toSlice().concat(eventType.toSlice());
                    ret = ret.toSlice().concat("\"".toSlice());
                    ret = ret.toSlice().concat(",\"eventHash\":\"".toSlice());
                    ret = ret.toSlice().concat(eventHash.toSlice());
                    ret = ret.toSlice().concat("\",\"eventData\":\"".toSlice());
                    ret = ret.toSlice().concat(eventData.toSlice());
                    ret = ret.toSlice().concat("\",\"eventTime\":\"".toSlice());
                    ret = ret.toSlice().concat(eventTime.toString().toSlice());
                    ret = ret.toSlice().concat("\",\"eventBlock\":\"".toSlice());
                    ret = ret.toSlice().concat(eventBlock.toString().toSlice());
                    ret = ret.toSlice().concat("\",\"changedBy\":\"".toSlice());
                    ret = ret.toSlice().concat(changedBy.toString().toSlice());
                    ret = ret.toSlice().concat("\"}".toSlice());
                    append = true;
               }
            }
            ret = ret.toSlice().concat("]".toSlice()).toSlice().toString();
            ret = ret.toSlice().concat("}".toSlice()).toSlice().toString();
            return ret;
        } else {
            return traceableToJson(traceable, true, true);
        }
    }

    function assessmentToJson(Assessment item, bool encloseTag) internal view returns (string memory){
        string memory ret =  encloseTag ? ("{".toSlice().toString()) : "";
        ret = ret.toSlice().concat(" \"evaluator\":\"".toSlice()).toSlice().concat(item.evaluator().toString().toSlice()).toSlice().concat("\"".toSlice());
        ret = ret.toSlice().concat(",\"data\":\"".toSlice()).toSlice().concat(item.data().toSlice()).toSlice().concat("\"".toSlice());
        ret = ret.toSlice().concat(",\"hash\":\"".toSlice()).toSlice().concat(item.hash().toSlice()).toSlice().concat("\"".toSlice());
        ret = ret.toSlice().concat(",\"blockNumber\":\"".toSlice()).toSlice().concat(item.assessBlockNumber().toString().toSlice()).toSlice().concat("\"".toSlice());
        ret = ret.toSlice().concat(",\"time\":\"".toSlice()).toSlice().concat(item.assessTime().toString().toSlice()).toSlice().concat("\"".toSlice());
        ret = ret.toSlice().concat(",\"tokenId\":\"".toSlice()).toSlice().concat(item.tokenId().toString().toSlice()).toSlice().concat("\"".toSlice());
        if ( encloseTag)
            ret = ret.toSlice().concat("}".toSlice());
        return ret;
    }

    function traceableToBriefJson(Traceable item, bool encloseTag) internal view returns (string memory){
      string memory ret =  encloseTag ? ("{".toSlice().toString()) : "";
      ret = ret.toSlice().concat(" \"label\":\"".toSlice()).toSlice().concat(item.label().toSlice()).toSlice().concat("\"".toSlice());
      ret = ret.toSlice().concat(",\"createTime\":".toSlice()).toSlice().concat(item.createTime().toString().toSlice());
      ret = ret.toSlice().concat(",\"createBlock\":".toSlice()).toSlice().concat(item.createBlock().toString().toSlice());
      ret = ret.toSlice().concat(",\"owner\":\"".toSlice()).toSlice().concat(item.owner().toString().toSlice()).toSlice().concat("\"".toSlice());
      ret = ret.toSlice().concat(",\"traceableType\":\"".toSlice()).toSlice().concat(item.traceableType().toSlice()).toSlice().concat("\"".toSlice());
      ret = ret.toSlice().concat(",\"tokenId\":\"".toSlice()).toSlice().concat(item.tokenId().toString().toSlice()).toSlice().concat("\"".toSlice());
      if ( encloseTag)
        ret = ret.toSlice().concat("}".toSlice());
      return ret;
    }

    function traceableToJson(Traceable item, bool encloseTag, bool contents ) internal view returns (string memory){
        string memory ret =  encloseTag ? ("{".toSlice().toString()) : "";
        ret = ret.toSlice().concat(" \"label\":\"".toSlice()).toSlice().concat(item.label().toSlice()).toSlice().concat("\"".toSlice());
        ret = ret.toSlice().concat(",\"createTime\":".toSlice()).toSlice().concat(item.createTime().toString().toSlice());
        ret = ret.toSlice().concat(",\"createBlock\":".toSlice()).toSlice().concat(item.createBlock().toString().toSlice());
        ret = ret.toSlice().concat(",\"owner\":\"".toSlice()).toSlice().concat(item.owner().toString().toSlice()).toSlice().concat("\"".toSlice());
        ret = ret.toSlice().concat(",\"traceableType\":\"".toSlice()).toSlice().concat(item.traceableType().toSlice()).toSlice().concat("\"".toSlice());
        ret = ret.toSlice().concat(",\"rawMetaData\":\"".toSlice()).toSlice().concat(item.rawMetadata().toSlice()).toSlice().concat("\"".toSlice());
        ret = ret.toSlice().concat(",\"hashMetaData\":\"".toSlice()).toSlice().concat(item.hashMetadata().toSlice()).toSlice().concat("\"".toSlice());
        ret = ret.toSlice().concat(",\"tokenId\":\"".toSlice()).toSlice().concat(item.tokenId().toString().toSlice()).toSlice().concat("\"".toSlice());
        ret = ret.toSlice().concat(",\"quantity\":".toSlice()).toSlice().concat(item.quantity().toString().toSlice());
        ret = ret.toSlice().concat(",\"partiallyTransferable\":".toSlice()).toSlice().concat((item.partiallyTransferable()? "true": "false").toSlice());
        //ret = ret.toSlice().concat(",\"ready\":".toSlice()).toSlice().concat((item.isReady()? "true": "false").toSlice());
        Assessment[] memory assessments = item.assessments();
        ret = ret.toSlice().concat(",\"assessments\":[".toSlice());
        bool append = false;
        for(uint256 i = 0; i < assessments.length; i++ ){
            Assessment assessment  = assessments[i];
            if ( append ){
                ret = ret.toSlice().concat(",".toSlice());
            }
            ret = ret.toSlice().concat("{".toSlice()).toSlice().concat(assessmentToJson(assessment, false).toSlice());
            ret = ret.toSlice().concat("}".toSlice());
            append = true;
        }
        ret = ret.toSlice().concat("]".toSlice()).toSlice().toString();
        if ( contents ){
           append = false;
           ret = ret.toSlice().concat(",\"contents\":[".toSlice());
           for(uint256 i = 0; i < item.contentsLength(); i++ ){
               (Traceable t ,uint256 q)  = item.contentAt(i);
               if ( append ){
                  ret = ret.toSlice().concat(",".toSlice());
               }
               ret = ret.toSlice().concat("{".toSlice()).toSlice().concat(traceableToJson(t, false, false).toSlice());
               ret = ret.toSlice().concat(" ,\"quantity\":".toSlice()).toSlice().concat(q.toString().toSlice()).toSlice().concat("}".toSlice());
               append = true;
            }
            ret = ret.toSlice().concat("]".toSlice()).toSlice().toString();

            append = false;
            ret = ret.toSlice().concat(",\"holders\":[".toSlice());
            for(uint256 i = 0; i < item.holdersLength(); i++ ){
                (Traceable t ,uint256 q)  = item.holderAt(i);
                if ( append ){
                    ret = ret.toSlice().concat(",".toSlice());
                }
                ret = ret.toSlice().concat("{".toSlice()).toSlice().concat(traceableToBriefJson(t, false).toSlice());
                ret = ret.toSlice().concat(" ,\"quantity\":".toSlice()).toSlice().concat(q.toString().toSlice()).toSlice().concat("}".toSlice());
                append = true;
            }
            ret = ret.toSlice().concat("]".toSlice()).toSlice().toString();
        }
        if ( encloseTag)
          ret = ret.toSlice().concat("}".toSlice());
        return ret;
    }



}

pragma solidity ^0.5.0;

import "../../lib/SafeMath.sol";
import "../../lib/AddressUtil.sol";
import "../../tracing/Traceable.sol";
import "../../tracing/TraceManager.sol";
import "../../lib/Strings.sol";

contract TraceableReporterCompact1 {

    using Strings for *;

    constructor() public {

    }

    function report(address tm, string calldata label, bool brief) external view returns (string memory){
        TraceManager traceManager = TraceManager(tm);
        Traceable traceable = traceManager.getTraceable(label);
        Traceable[] memory chain = new Traceable[](traceable.chainLength());

        Traceable loopItem = traceable;
        for (uint i = 0; i < traceable.chainLength(); i++) {
            chain[i] = loopItem;
            loopItem = loopItem.genesis();
        }
        string memory ret = "{";
        ret = ret.toSlice().concat(traceableToJson(traceable, false, brief).toSlice());
        ret = ret.toSlice().concat(",".toSlice()).toSlice().concat(assessmentsToJson(traceManager, traceable, false, true).toSlice());
        ret = ret.toSlice().concat(",".toSlice()).toSlice().concat(ownersToJson(traceManager, chain).toSlice());
        ret = ret.toSlice().concat(",".toSlice()).toSlice().concat(changesToJson(chain).toSlice());
        ret = ret.toSlice().concat("}".toSlice());
        return ret;
    }

    function changesToJson(Traceable[] memory chain) internal view returns (string memory){
        bool append = false;
        string memory ret = "\"changes\":[";
        for (uint i = chain.length; i > 1; i--) {
            Traceable nextT = chain[i - 2];
            uint256 nextB = nextT.createBlock();
            uint256 changesLength = chain[i - 1].changesLength();
            for (uint j = 0; j < changesLength; j++) {
                (string memory eventId,
                string memory eventType,
                string memory eventHash,
                string memory eventData,
                uint256 eventTime,
                uint256 eventBlock,
                address changedBy) = chain[i - 1].changesAt(j);
                if (eventBlock > nextB)
                    break;
                if (append) {
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
        return ret;
    }

    function identityToJson(TraceManager traceManager, address owner) internal view returns (string memory){
        string memory ret = "{\"address\":\"".toSlice().concat(owner.toString().toSlice()).toSlice().concat("\"".toSlice());
        Traceable traceable = traceManager.getTraceable("ID0x".toSlice().concat(owner.toString().toSlice()));
        if (address(traceable) != address(0)) {
            string memory title = traceable.rawMetadata();
            ret = ret.toSlice().concat(",\"title\":\"".toSlice()).toSlice().concat(title.toSlice()).toSlice().concat("\"".toSlice());
            if (traceable.contentsLength() > 0) {
                (Traceable register, uint256 q) = traceable.contentAt(0);
                string memory registerNo = register.rawMetadata();
                ret = ret.toSlice().concat(",\"registerNo\":\"".toSlice()).toSlice().concat(registerNo.toSlice()).toSlice().concat("\"".toSlice());
            }
        }
        ret = ret.toSlice().concat("}".toSlice());
        return ret;
    }

    function ownersToJson(TraceManager traceManager,Traceable[] memory chain) internal view returns (string memory){
        string memory ret = "\"owners\":[";
        bool append = false;
        for (uint i = chain.length; i > 0; i--) {
            if (append) {
                ret = ret.toSlice().concat(",".toSlice());
            }
            ret = ret.toSlice().concat("{ \"owner\": ".toSlice());
            ret = ret.toSlice().concat(identityToJson(traceManager, chain[i - 1].owner()).toSlice());
            ret = ret.toSlice().concat(", \"date\": \"".toSlice()).toSlice().concat(chain[i - 1].createTime().toString().toSlice()).toSlice().concat("\"".toSlice());
            ret = ret.toSlice().concat(", \"blockNumber\": \"".toSlice()).toSlice().concat(chain[i - 1].createBlock().toString().toSlice()).toSlice().concat("\"}".toSlice());
            append = true;
        }
        ret = ret.toSlice().concat("]".toSlice());
        return ret;
    }

    function assessmentsToJson(TraceManager traceManager, Traceable item, bool append, bool checkChain) internal view returns (string memory){
        Assessment[] memory assessments = item.assessments();
        bool assessAppend = append;
        string memory assessmentReport = append ? "" : "\"assessments\":[".toSlice().toString();
        for (uint256 i = 0; i < assessments.length; i++) {
            Assessment assessment = assessments[i];
            if (assessAppend) {
                assessmentReport = assessmentReport.toSlice().concat(",".toSlice());
            }
            assessmentReport = assessmentReport.toSlice().concat("{".toSlice()).toSlice().concat(assessmentToJson(traceManager, assessment, false).toSlice());
            assessmentReport = assessmentReport.toSlice().concat("}".toSlice());
            assessAppend = true;
        }
        if (checkChain) {
            Traceable[] memory chain = new Traceable[](item.chainLength());
            Traceable loopItem = item;
            for (uint i = 0; i < item.chainLength(); i++) {
                chain[i] = loopItem;
                loopItem = loopItem.genesis();
            }

            for (uint i = chain.length; i > 1; i--) {
                assessments = chain[i - 1].assessments();
                for (uint256 i = 0; i < assessments.length; i++) {
                    Assessment assessment = assessments[i];
                    if (assessAppend) {
                        assessmentReport = assessmentReport.toSlice().concat(",".toSlice());
                    }
                    assessmentReport = assessmentReport.toSlice().concat("{".toSlice()).toSlice().concat(assessmentToJson(traceManager, assessment, false).toSlice());
                    assessmentReport = assessmentReport.toSlice().concat("}".toSlice());
                    assessAppend = true;
                }
            }
        }
        assessmentReport = assessmentReport.toSlice().concat("]".toSlice()).toSlice().toString();

        return (assessmentReport);
    }

    function assessmentToJson(TraceManager traceManager, Assessment item, bool encloseTag) internal view returns (string memory){
        string memory ret = encloseTag ? ("{".toSlice().toString()) : "";
        ret = ret.toSlice().concat(" \"evaluator\":".toSlice()).toSlice().concat(identityToJson(traceManager, item.evaluator()).toSlice()).toSlice().concat("".toSlice());
        ret = ret.toSlice().concat(",\"data\":\"".toSlice()).toSlice().concat(item.data().toSlice()).toSlice().concat("\"".toSlice());
        ret = ret.toSlice().concat(",\"hash\":\"".toSlice()).toSlice().concat(item.hash().toSlice()).toSlice().concat("\"".toSlice());
        ret = ret.toSlice().concat(",\"blockNumber\":\"".toSlice()).toSlice().concat(item.assessBlockNumber().toString().toSlice()).toSlice().concat("\"".toSlice());
        ret = ret.toSlice().concat(",\"time\":\"".toSlice()).toSlice().concat(item.assessTime().toString().toSlice()).toSlice().concat("\"".toSlice());
        ret = ret.toSlice().concat(",\"tokenId\":\"".toSlice()).toSlice().concat(item.tokenId().toString().toSlice()).toSlice().concat("\"".toSlice());
        if (encloseTag)
            ret = ret.toSlice().concat("}".toSlice());
        return ret;
    }


    function traceableToJson(Traceable item, bool encloseTag, bool contents) internal view returns (string memory){
        string memory ret = encloseTag ? ("{".toSlice().toString()) : "";
        ret = ret.toSlice().concat(" \"label\":\"".toSlice()).toSlice().concat(item.label().toSlice()).toSlice().concat("\"".toSlice());
        ret = ret.toSlice().concat(",\"createTime\":".toSlice()).toSlice().concat(item.createTime().toString().toSlice());
        ret = ret.toSlice().concat(",\"createBlock\":".toSlice()).toSlice().concat(item.createBlock().toString().toSlice());
        ret = ret.toSlice().concat(",\"traceableType\":\"".toSlice()).toSlice().concat(item.traceableType().toSlice()).toSlice().concat("\"".toSlice());
        ret = ret.toSlice().concat(",\"rawMetaData\":\"".toSlice()).toSlice().concat(item.rawMetadata().toSlice()).toSlice().concat("\"".toSlice());
        ret = ret.toSlice().concat(",\"hashMetaData\":\"".toSlice()).toSlice().concat(item.hashMetadata().toSlice()).toSlice().concat("\"".toSlice());
        ret = ret.toSlice().concat(",\"tokenId\":\"".toSlice()).toSlice().concat(item.tokenId().toString().toSlice()).toSlice().concat("\"".toSlice());
        ret = ret.toSlice().concat(",\"quantity\":".toSlice()).toSlice().concat(item.quantity().toString().toSlice());
        ret = ret.toSlice().concat(",\"partiallyTransferable\":".toSlice()).toSlice().concat((item.partiallyTransferable() ? "true" : "false").toSlice());

        if (contents) {
            bool append = false;
            ret = ret.toSlice().concat(",\"contents\":[".toSlice());
            for (uint256 i = 0; i < item.contentsLength(); i++) {
                (Traceable t, uint256 q) = item.contentAt(i);
                if (append) {
                    ret = ret.toSlice().concat(",".toSlice());
                }
                ret = ret.toSlice().concat("{".toSlice()).toSlice().concat(traceableToJson(t, false, false).toSlice());
                ret = ret.toSlice().concat(" ,\"quantity\":".toSlice()).toSlice().concat(q.toString().toSlice()).toSlice().concat("}".toSlice());
                append = true;
            }
            ret = ret.toSlice().concat("]".toSlice()).toSlice().toString();

            append = false;
            ret = ret.toSlice().concat(",\"holders\":[".toSlice());
            for (uint256 i = 0; i < item.holdersLength(); i++) {
                (Traceable t, uint256 q) = item.holderAt(i);
                if (append) {
                    ret = ret.toSlice().concat(",".toSlice());
                }
                ret = ret.toSlice().concat("{".toSlice()).toSlice().concat(traceableToJson(t, false, false).toSlice());
                ret = ret.toSlice().concat(" ,\"quantity\":".toSlice()).toSlice().concat(q.toString().toSlice()).toSlice().concat("}".toSlice());
                append = true;
            }
            ret = ret.toSlice().concat("]".toSlice()).toSlice().toString();
        }
        if (encloseTag)
            ret = ret.toSlice().concat("}".toSlice());
        return ret;
    }


}

import { Errors } from "../../../shared/http/app-error.js";
export class ChairAllocator {
    repository;
    constructor(repository) {
        this.repository = repository;
    }
    /**
     * Walk-ins only use non-reserved chairs; BookBer queue only uses reserved chairs.
     */
    async findAvailableChair(db, shopId, lane) {
        return this.repository.findAvailableChairForLane(db, shopId, lane);
    }
    async allocateToBooking(db, args) {
        const chair = args.chair;
        if (args.lane === "WALKIN" && chair.reservedForBookBer) {
            throw Errors.conflict("Walk-in cannot use BookBer reserved chair");
        }
        if (args.lane === "BOOKBER" && !chair.reservedForBookBer) {
            throw Errors.conflict("BookBer customer requires a reserved chair");
        }
        return this.repository.assignChair(db, {
            shopId: args.shopId,
            chairId: chair.id,
            bookingId: args.bookingId,
            ...(args.startNow ? { activeServiceStart: new Date() } : {})
        });
    }
}

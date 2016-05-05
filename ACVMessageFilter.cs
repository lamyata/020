using System;
using iBoris.Unicorn;
using iBoris.Unicorn.Mapping;
using iBoris.iTos.Orders;
using System.Collections.Generic;

namespace iBoris.iTos.VMG
{
    [Serializable]
    public class ACVMessageFilter : EntityFilter
    {
        public string ExternalId { get; set; }

        [MapIgnore]
        public bool? HasOrderItem { get; set; }

        [MapIgnore]
        public bool NotConfirmed { get; set; }

        [MapIgnore]
        public DateTime? DateFrom { get; set; }

        [MapIgnore]
        public DateTime? DateTo { get; set; }

        #region Protected members
        protected override Dictionary<string, string> GetOrderExpressionsMapping()
        {
            EnsureSortExpressionsMapping();
            return sortExpressionsMapping;
        }
        #endregion

        #region Private members
        private static void EnsureSortExpressionsMapping()
        {
            if (sortExpressionsMapping == null)
            {
                lock (sortExpressionsSyncRoot)
                {
                    if (sortExpressionsMapping == null)
                    {
                        var mapping = new Dictionary<string, string>();
                        mapping.Add("DateReceivedServerFormatted", "DeliveryHttpLogItem.RequestTimestamp");
                        mapping.Add("DateOfConfirmationServerFormatted", "CompleteHttpLogItem.CreateTimestamp");
                        mapping.Add("OrderItemOrderNumber", "OrderItem.Order.Number|OrderItem.Sequence");
                        mapping.Add("OperationInfo", "OrderItem.OperationType.Description|OrderItem.Operation.Name");
                        mapping.Add("OrderItemStatusText", "OrderItem.Status");
                        mapping.Add("OrderCustomer", "OrderItem.Order.Customer.NickName");
                        sortExpressionsMapping = mapping;
                    }
                }
            }
        }
        private static Dictionary<string, string> sortExpressionsMapping;
        private static readonly object sortExpressionsSyncRoot = new object();
        #endregion

    }
}
package http

import (
	"encoding/json"
	"testing"
	"xiaoheiplay/internal/domain"
)

func metaJSON(m map[string]any) string {
	b, _ := json.Marshal(m)
	return string(b)
}

func TestWalletPaymentMatched(t *testing.T) {
	tests := []struct {
		name     string
		item     domain.WalletOrder
		provider string
		orderNo  string
		tradeNo  string
		want     bool
	}{
		{
			name: "match by orderNo in meta",
			item: domain.WalletOrder{
				ID: 42,
				MetaJSON: metaJSON(map[string]any{
					"payment_method":   "mockpay",
					"payment_order_no": "PAY-123",
					"payment_trade_no": "TXN-456",
				}),
			},
			provider: "mockpay",
			orderNo:  "PAY-123",
			tradeNo:  "",
			want:     true,
		},
		{
			name: "match by tradeNo in meta",
			item: domain.WalletOrder{
				ID: 42,
				MetaJSON: metaJSON(map[string]any{
					"payment_method":   "mockpay",
					"payment_order_no": "PAY-123",
					"payment_trade_no": "TXN-456",
				}),
			},
			provider: "mockpay",
			orderNo:  "",
			tradeNo:  "TXN-456",
			want:     true,
		},
		{
			name: "match by derived orderNo (WALLET-ORDER-{id})",
			item: domain.WalletOrder{
				ID: 42,
				MetaJSON: metaJSON(map[string]any{
					"payment_method": "mockpay",
				}),
			},
			provider: "mockpay",
			orderNo:  "WALLET-ORDER-42",
			tradeNo:  "",
			want:     true,
		},
		{
			name: "no match - wrong provider",
			item: domain.WalletOrder{
				ID: 42,
				MetaJSON: metaJSON(map[string]any{
					"payment_method":   "alipay",
					"payment_order_no": "PAY-123",
					"payment_trade_no": "TXN-456",
				}),
			},
			provider: "mockpay",
			orderNo:  "PAY-123",
			tradeNo:  "TXN-456",
			want:     false,
		},
		{
			name: "no match - empty orderNo and tradeNo",
			item: domain.WalletOrder{
				ID: 42,
				MetaJSON: metaJSON(map[string]any{
					"payment_method":   "mockpay",
					"payment_order_no": "PAY-123",
					"payment_trade_no": "TXN-456",
				}),
			},
			provider: "mockpay",
			orderNo:  "",
			tradeNo:  "",
			want:     false,
		},
		{
			name: "no match - orderNo mismatch",
			item: domain.WalletOrder{
				ID: 42,
				MetaJSON: metaJSON(map[string]any{
					"payment_method":   "mockpay",
					"payment_order_no": "PAY-123",
				}),
			},
			provider: "mockpay",
			orderNo:  "PAY-999",
			tradeNo:  "",
			want:     false,
		},
		{
			name: "no match - tradeNo mismatch",
			item: domain.WalletOrder{
				ID: 42,
				MetaJSON: metaJSON(map[string]any{
					"payment_method":   "mockpay",
					"payment_trade_no": "TXN-456",
				}),
			},
			provider: "mockpay",
			orderNo:  "",
			tradeNo:  "TXN-999",
			want:     false,
		},
		{
			name: "match - empty meta fields, derived orderNo still works",
			item: domain.WalletOrder{
				ID: 100,
				MetaJSON: metaJSON(map[string]any{
					"payment_method": "stripe",
				}),
			},
			provider: "stripe",
			orderNo:  "WALLET-ORDER-100",
			tradeNo:  "",
			want:     true,
		},
		{
			name: "no match - empty metaJSON",
			item: domain.WalletOrder{
				ID:       42,
				MetaJSON: "",
			},
			provider: "mockpay",
			orderNo:  "WALLET-ORDER-42",
			tradeNo:  "",
			want:     false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := walletPaymentMatched(tt.item, tt.provider, tt.orderNo, tt.tradeNo)
			if got != tt.want {
				t.Errorf("walletPaymentMatched() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestWalletPaymentOrderNo(t *testing.T) {
	tests := []struct {
		orderID int64
		want    string
	}{
		{1, "WALLET-ORDER-1"},
		{42, "WALLET-ORDER-42"},
		{9999, "WALLET-ORDER-9999"},
	}
	for _, tt := range tests {
		got := walletPaymentOrderNo(tt.orderID)
		if got != tt.want {
			t.Errorf("walletPaymentOrderNo(%d) = %q, want %q", tt.orderID, got, tt.want)
		}
	}
}

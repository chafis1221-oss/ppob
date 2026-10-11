package main

import (
	"bytes"
	"crypto/hmac"
	"crypto/md5"
	"crypto/sha1"
	"crypto/subtle"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"sync"
)

type Config struct {
	BaseURL, Username, APIKey, WebhookSecret string
	Mock                                     bool
}
type Client struct {
	cfg  Config
	http *http.Client
}

func env(k, d string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return d
}
func loadConfig() Config {
	return Config{env("DIGIFLAZZ_BASE_URL", "https://api.digiflazz.com/v1"), os.Getenv("DIGIFLAZZ_USERNAME"), os.Getenv("DIGIFLAZZ_API_KEY"), os.Getenv("DIGIFLAZZ_WEBHOOK_SECRET"), strings.EqualFold(env("DIGIFLAZZ_MOCK", "false"), "true")}
}
func sign(s string) string { h := md5.Sum([]byte(s)); return hex.EncodeToString(h[:]) }
func (c Client) call(path string, body map[string]any) (map[string]any, error) {
	if c.cfg.Mock {
		return map[string]any{"data": map[string]any{"status": "Sukses", "rc": "00", "message": "Mock response", "ref_id": body["ref_id"]}}, nil
	}
	b, _ := json.Marshal(body)
	req, e := http.NewRequest(http.MethodPost, strings.TrimRight(c.cfg.BaseURL, "/")+path, bytes.NewReader(b))
	if e != nil {
		return nil, e
	}
	req.Header.Set("Content-Type", "application/json")
	r, e := c.http.Do(req)
	if e != nil {
		return nil, e
	}
	defer r.Body.Close()
	if r.StatusCode/100 != 2 {
		return nil, fmt.Errorf("provider HTTP %s", r.Status)
	}
	var out map[string]any
	e = json.NewDecoder(r.Body).Decode(&out)
	return out, e
}
func (c Client) common(body map[string]any) { body["username"] = c.cfg.Username }
func (c Client) request(cmd string, in map[string]any) (map[string]any, error) {
	c.common(in)
	in["commands"] = cmd
	if cmd == "deposit" {
		in["cmd"] = "deposit"
		in["sign"] = sign(c.cfg.Username + c.cfg.APIKey + "depo")
		return c.call("/cek-saldo", in)
	}
	if cmd == "prepaid" {
		in["cmd"] = "prepaid"
		in["sign"] = sign(c.cfg.Username + c.cfg.APIKey + "pricelist")
		return c.call("/price-list", in)
	}
	in["sign"] = sign(c.cfg.Username + c.cfg.APIKey + fmt.Sprint(in["ref_id"]))
	return c.call("/transaction", in)
}

type Store struct {
	sync.Mutex
	refs map[string][]byte
}

func main() {
	cfg := loadConfig()
	if !cfg.Mock && (cfg.Username == "" || cfg.APIKey == "") {
		log.Fatal("DIGIFLAZZ_USERNAME and DIGIFLAZZ_API_KEY required (or DIGIFLAZZ_MOCK=true)")
	}
	c := Client{cfg, http.DefaultClient}
	s := &Store{refs: map[string][]byte{}}
	mux := http.NewServeMux()
	jsonHandler := func(fn func(map[string]any) (map[string]any, error)) http.HandlerFunc {
		return func(w http.ResponseWriter, r *http.Request) {
			if r.Method != "POST" {
				http.Error(w, "method not allowed", 405)
				return
			}
			var in map[string]any
			d, e := io.ReadAll(io.LimitReader(r.Body, 1<<20))
			if e == nil {
				e = json.Unmarshal(d, &in)
			}
			if e != nil {
				http.Error(w, "invalid JSON", 400)
				return
			}
			out, e := fn(in)
			if e != nil {
				http.Error(w, e.Error(), 502)
				return
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(out)
		}
	}
	mux.Handle("/api/price-list", jsonHandler(func(in map[string]any) (map[string]any, error) { return c.request("prepaid", in) }))
	mux.Handle("/api/balance", jsonHandler(func(in map[string]any) (map[string]any, error) { return c.request("deposit", in) }))
	tx := func(cmd string) http.Handler {
		return jsonHandler(func(in map[string]any) (map[string]any, error) {
			ref, ok := in["ref_id"].(string)
			if !ok || ref == "" {
				return nil, errors.New("ref_id required")
			}
			s.Lock()
			defer s.Unlock()
			if old := s.refs[ref]; old != nil {
				var out map[string]any
				json.Unmarshal(old, &out)
				return out, nil
			}
			out, e := c.request(cmd, in)
			if e == nil {
				s.refs[ref], _ = json.Marshal(out)
			}
			return out, e
		})
	}
	mux.Handle("/api/prepaid", tx("topup"))
	mux.Handle("/api/postpaid/inquiry", tx("inq-pasca"))
	mux.Handle("/api/postpaid/payment", tx("pay-pasca"))
	mux.Handle("/api/status", tx("status-pasca"))
	mux.HandleFunc("/webhooks/digiflazz", func(w http.ResponseWriter, r *http.Request) {
		b, _ := io.ReadAll(io.LimitReader(r.Body, 1<<20))
		if cfg.WebhookSecret != "" {
			got := strings.TrimPrefix(r.Header.Get("X-Hub-Signature"), "sha1=")
			h := hmac.New(sha1.New, []byte(cfg.WebhookSecret))
			h.Write(b)
			want := hex.EncodeToString(h.Sum(nil))
			if subtle.ConstantTimeCompare([]byte(got), []byte(want)) != 1 {
				http.Error(w, "invalid signature", 401)
				return
			}
		}
		w.WriteHeader(http.StatusNoContent)
	})
	log.Printf("backend listening on :8080 mock=%v", cfg.Mock)
	log.Fatal(http.ListenAndServe(":8080", mux))
}

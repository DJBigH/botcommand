from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher
from typing import Any, Text, Dict, List
import requests


class ActionDynamicResponse(Action):
    def name(self) -> Text:
        return "action_dynamic_response"

    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: Dict[Text, Any]
    ) -> List[Dict[Text, Any]]:
        try:
            response = requests.get("http://localhost:3000/api/products/hot")
            response.raise_for_status()
            products = response.json()

            if not products:
                dispatcher.utter_message(text="Hiện tại không có sản phẩm hot nào.")
                return []

            message = "🔥 Các sản phẩm hot hôm nay:\n"
            for p in products:
                name = p.get("name", "Không rõ")
                price = p.get("price", "N/A")
                message += f"- {name} ({price}đ)\n"

            dispatcher.utter_message(text=message)

        except Exception as e:
            print("[ERROR API]", str(e))
            dispatcher.utter_message(text="Không thể lấy thông tin sản phẩm hiện tại.")

        return []


class ActionSearchProducts(Action):
    def name(self) -> Text:
        return "action_search_products"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:

        keyword = tracker.get_slot("keyword")
        if not keyword:
            dispatcher.utter_message(text="Bạn muốn tìm sản phẩm gì?")
            return []

        try:
            response = requests.get("http://localhost:3000/api/products/search", params={"keyword": keyword})
            products = response.json()

            if not products:
                dispatcher.utter_message(text=f"Không tìm thấy sản phẩm nào với từ khóa '{keyword}'.")
            else:
                message = f"Kết quả cho từ khóa '{keyword}':\n"
                for p in products:
                    message += f"- {p['name']} ({p['price']} VNĐ)\n"
                dispatcher.utter_message(text=message)

        except Exception as e:
            dispatcher.utter_message(text="Lỗi khi tìm kiếm sản phẩm.")
            print(f"[Keyword Search Error]: {e}")

        return []


class ActionProductsByPriceRange(Action):
    def name(self) -> Text:
        return "action_products_by_price_range"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:

        min_price = tracker.get_slot("min_price")
        max_price = tracker.get_slot("max_price")

        if not min_price or not max_price:
            dispatcher.utter_message(text="Vui lòng cung cấp khoảng giá (tối thiểu và tối đa).")
            return []

        try:
            response = requests.get("http://localhost:3000/api/products/by_price_range", params={
                "min": min_price,
                "max": max_price
            })
            products = response.json()

            if not products:
                dispatcher.utter_message(text="Không có sản phẩm nào trong khoảng giá này.")
            else:
                message = f"Các sản phẩm từ {min_price} đến {max_price} VNĐ:\n"
                for p in products:
                    message += f"- {p['name']} ({p['price']} VNĐ)\n"
                dispatcher.utter_message(text=message)

        except Exception as e:
            dispatcher.utter_message(text="Đã xảy ra lỗi khi truy xuất sản phẩm theo giá.")
            print(f"[PriceRange Error]: {e}")

        return []